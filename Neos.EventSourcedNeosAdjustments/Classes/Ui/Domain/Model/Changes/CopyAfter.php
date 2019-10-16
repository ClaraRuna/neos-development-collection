<?php
declare(strict_types=1);
namespace Neos\EventSourcedNeosAdjustments\Ui\Domain\Model\Changes;


/*
 * This file is part of the Neos.Neos.Ui package.
 *
 * (c) Contributors of the Neos Project - www.neos.io
 *
 * This package is Open Source Software. For the full copyright and license
 * information, please view the LICENSE file which was distributed with this
 * source code.
 */

use Neos\ContentRepository\Domain\NodeAggregate\NodeName;
use Neos\EventSourcedContentRepository\Domain\Context\NodeDuplication\Command\Dto\NodeToInsert;
use Neos\EventSourcedNeosAdjustments\Ui\Fusion\Helper\NodeInfoHelper;
use Neos\Flow\Annotations as Flow;
use Neos\EventSourcedContentRepository\Domain\Context\NodeDuplication\Command\CopyNodesRecursively;
use Neos\EventSourcedContentRepository\Domain\Context\NodeDuplication\NodeDuplicationCommandHandler;
use Neos\EventSourcedContentRepository\Domain\ValueObject\UserIdentifier;

class CopyAfter extends AbstractStructuralChange
{

    /**
     * @Flow\Inject
     * @var NodeDuplicationCommandHandler
     */
    protected $nodeDuplicationCommandHandler;

    /**
     * "Subject" is the to-be-copied node; the "sibling" node is the node after which the "Subject" should be copied.
     *
     * @return boolean
     */
    public function canApply()
    {
        $nodeType = $this->getSubject()->getNodeType();
        return NodeInfoHelper::isNodeTypeAllowedAsChildNode($this->getSiblingNode()->findParentNode(), $nodeType);
    }

    public function getMode()
    {
        return 'after';
    }

    /**
     * Applies this change
     *
     * @return void
     */
    public function apply()
    {
        if ($this->canApply()) {
            $subject = $this->getSubject();

            $previousSibling = $this->getSiblingNode();
            $parentNodeOfPreviousSibling = $previousSibling->findParentNode();
            $succeedingSibling = null;
            try {
                $succeedingSibling = $parentNodeOfPreviousSibling->findChildNodes()->next($previousSibling);
            } catch (\InvalidArgumentException $e) {
                // do nothing; $succeedingSibling is null.
            }

            $command = new CopyNodesRecursively(
                $subject->getContentStreamIdentifier(),
                NodeToInsert::fromTraversableNode($subject)->withNodeName(NodeName::fromString(uniqid('node-'))),
                $subject->getDimensionSpacePoint(),
                UserIdentifier::forSystemUser(), // TODO
                $parentNodeOfPreviousSibling->getNodeAggregateIdentifier(),
                $succeedingSibling ? $succeedingSibling->getNodeAggregateIdentifier() : null
            );

            $this->contentCacheFlusher->registerNodeChange($subject);

            // NOTE: the following line internally *always blocks*; I still dislike that this API is somehow "different" than the
            // others.
            $this->nodeDuplicationCommandHandler->handleCopyNodesRecursively($command);

            $this->finish($parentNodeOfPreviousSibling);
        }
    }
}
