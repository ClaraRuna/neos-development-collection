<?php
namespace Neos\Fusion\FusionObjects;

/*
 * This file is part of the Neos.Fusion package.
 *
 * (c) Contributors of the Neos Project - www.neos.io
 *
 * This package is Open Source Software. For the full copyright and license
 * information, please view the LICENSE file which was distributed with this
 * source code.
 */


/**
 * Matcher object for use inside a "Case" statement
 */
class MatcherImplementation extends AbstractFusionObject
{
    use RendererTrait;

    public function evaluate()
    {
        if (!$this->fusionValue('condition')) {
            return CaseImplementation::MATCH_NORESULT;
        }
        return $this->evaluateRenderer();
    }
}
