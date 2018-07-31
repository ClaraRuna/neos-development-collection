<?php

namespace Neos\ContentRepository\DimensionSpace\DimensionSpace\Exception;

/*
 * This file is part of the Neos.ContentRepository.DimensionSpace package.
 *
 * (c) Contributors of the Neos Project - www.neos.io
 *
 * This package is Open Source Software. For the full copyright and license
 * information, please view the LICENSE file which was distributed with this
 * source code.
 */

/**
 * The exception to be thrown if a dimension space point is tried to be used as a specialization of another one but isn't
 */
class DimensionSpacePointIsNoSpecialization extends \DomainException
{
}
