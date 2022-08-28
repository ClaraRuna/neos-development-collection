<?php
namespace Neos\ContentRepository\NodeAccess\FlowQueryOperations;

/*
 * This file is part of the Neos.ContentRepository package.
 *
 * (c) Contributors of the Neos Project - www.neos.io
 *
 * This package is Open Source Software. For the full copyright and license
 * information, please view the LICENSE file which was distributed with this
 * source code.
 */

use Neos\ContentRepositoryRegistry\ContentRepositoryRegistry;
use Neos\Flow\Annotations as Flow;
use Neos\Eel\FlowQuery\FlowQuery;
use Neos\Eel\FlowQuery\Operations\AbstractOperation;
use Neos\ContentRepository\Core\Projection\ContentGraph\Node;
use Neos\ContentRepository\Core\Projection\ContentGraph\Nodes;

/**
 * "nextAll" operation working on ContentRepository nodes. It iterates over all
 * context elements and returns each following sibling or only those matching
 * the filter expression specified as optional argument.
 */
class NextAllOperation extends AbstractOperation
{
    /**
     * {@inheritdoc}
     *
     * @var string
     */
    protected static $shortName = 'nextAll';

    /**
     * {@inheritdoc}
     *
     * @var integer
     */
    protected static $priority = 100;

    /**
     * @Flow\Inject
     * @var ContentRepositoryRegistry
     */
    protected $contentRepositoryRegistry;

    /**
     * {@inheritdoc}
     *
     * @param array<int,mixed> $context (or array-like object) onto which this operation should be applied
     * @return boolean true if the operation can be applied onto the $context, false otherwise
     */
    public function canEvaluate($context)
    {
        return count($context) === 0 || (isset($context[0]) && ($context[0] instanceof Node));
    }

    /**
     * {@inheritdoc}
     *
     * @param FlowQuery<int,mixed> $flowQuery the FlowQuery object
     * @param array<int,mixed> $arguments the arguments for this operation
     * @return void
     */
    public function evaluate(FlowQuery $flowQuery, array $arguments)
    {
        $output = [];
        $outputNodePaths = [];
        foreach ($flowQuery->getContext() as $contextNode) {
            foreach ($this->getNextForNode($contextNode) as $nextNode) {
                if ($nextNode !== null && !isset($outputNodePaths[(string)$nextNode->nodeAggregateIdentifier])) {
                    $outputNodePaths[(string)$nextNode->nodeAggregateIdentifier] = true;
                    $output[] = $nextNode;
                }
            }
        }
        $flowQuery->setContext($output);

        if (isset($arguments[0]) && !empty($arguments[0])) {
            $flowQuery->pushOperation('filter', $arguments);
        }
    }

    /**
     * @param Node $contextNode The node for which the next node should be found
     * @return Nodes The next nodes of $contextNode
     */
    protected function getNextForNode(Node $contextNode): Nodes
    {
        $subgraph = $this->contentRepositoryRegistry->subgraphForNode($contextNode);

        $parentNode = $subgraph->findParentNode($contextNode->nodeAggregateIdentifier);
        if ($parentNode === null) {
            return Nodes::createEmpty();
        }

        return $subgraph->findChildNodes($parentNode->nodeAggregateIdentifier)->nextAll($contextNode);
    }
}
