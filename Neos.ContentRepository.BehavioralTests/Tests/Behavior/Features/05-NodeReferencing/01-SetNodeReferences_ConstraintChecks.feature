@fixtures @adapters=DoctrineDBAL,Postgres
Feature: Constraint checks on SetNodeReferences

  As a user of the CR I expect invalid SetNodeReferences commands to be blocked

  Background:
    Given I have the following content dimensions:
      | Identifier | Values      | Generalizations |
      | language   | de, gsw, en | gsw->de, en     |
    And I have the following NodeTypes configuration:
    """
    'Neos.ContentRepository:Root': []
    'Neos.ContentRepository.Testing:NodeWithReferences':
      properties:
        referenceProperty:
          type: reference
        referencesProperty:
          type: references
        nonReferenceProperty:
          type: string
        constrainedReferenceProperty:
          type: reference
          constraints:
            nodeTypes:
              'Neos.ContentRepository.Testing:NodeWithReferences': false
        referencePropertyWithProperties:
          type: reference
          properties:
            text:
              type: string
            postalAddress:
              type: 'Neos\ContentRepository\Tests\Behavior\Fixtures\PostalAddress'
    """
    And I am user identified by "initiating-user-identifier"
    And the command CreateRootWorkspace is executed with payload:
      | Key                        | Value                |
      | workspaceName              | "live"               |
      | workspaceTitle             | "Live"               |
      | workspaceDescription       | "The live workspace" |
      | newContentStreamIdentifier | "cs-identifier"      |
    And the graph projection is fully up to date
    And I am in content stream "cs-identifier" and dimension space point {"language":"de"}
    And the command CreateRootNodeAggregateWithNode is executed with payload:
      | Key                     | Value                         |
      | nodeAggregateIdentifier | "lady-eleonode-rootford"      |
      | nodeTypeName            | "Neos.ContentRepository:Root" |
    And the graph projection is fully up to date
    And the following CreateNodeAggregateWithNode commands are executed:
      | nodeAggregateIdentifier | nodeTypeName                                      | parentNodeAggregateIdentifier |
      | source-nodandaise       | Neos.ContentRepository.Testing:NodeWithReferences | lady-eleonode-rootford        |
      | anthony-destinode       | Neos.ContentRepository.Testing:NodeWithReferences | lady-eleonode-rootford        |
      | berta-destinode         | Neos.ContentRepository.Testing:NodeWithReferences | lady-eleonode-rootford        |

  # checks for contentStreamIdentifier
  Scenario: Try to reference nodes in a non-existent content stream
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                           |
      | contentStreamIdentifier       | "i-do-not-exist"                |
      | sourceNodeAggregateIdentifier | "source-nodandaise"             |
      | referenceName                 | "referenceProperty"             |
      | references                    | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "ContentStreamDoesNotExistYet" with code 1521386692

  # checks for sourceNodeAggregateIdentifier
  Scenario: Try to reference nodes in a non-existent node aggregate
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                            |
      | sourceNodeAggregateIdentifier | "i-do-not-exist"                 |
      | referenceName                 | "referenceProperty"              |
      | references                    | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "NodeAggregateCurrentlyDoesNotExist" with code 1541678486

  Scenario: Try to reference nodes in a root node aggregate
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                            |
      | sourceNodeAggregateIdentifier | "lady-eleonode-rootford"         |
      | referenceName                 | "referenceProperty"              |
      | references                    | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "NodeAggregateIsRoot"

  # checks for sourceOriginDimensionSpacePoint
  Scenario: Try to reference nodes in an origin dimension space point that does not exist
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                             | Value                            |
      | sourceNodeAggregateIdentifier   | "source-nodandaise"              |
      | sourceOriginDimensionSpacePoint | {"undeclared":"undefined"}       |
      | referenceName                   | "referenceProperty"              |
      | references                      | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "DimensionSpacePointNotFound" with code 1505929456

  Scenario: Try to reference nodes in an origin dimension space point the source node aggregate does not occupy
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                             | Value                            |
      | sourceNodeAggregateIdentifier   | "source-nodandaise"              |
      | sourceOriginDimensionSpacePoint | {"language":"en"}                |
      | referenceName                   | "referenceProperty"              |
      | references                      | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "DimensionSpacePointIsNotYetOccupied" with code 1552595396

  # checks for destinationNodeAggregateIdentifiers
  Scenario: Try to reference a non-existent node aggregate
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                         |
      | sourceNodeAggregateIdentifier | "source-nodandaise"           |
      | referenceName                 | "referenceProperty"           |
      | references                    | [{"target":"i-do-not-exist"}] |
    Then the last command should have thrown an exception of type "NodeAggregateCurrentlyDoesNotExist" with code 1541678486

  Scenario: Try to reference a root node aggregate
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                                 |
      | sourceNodeAggregateIdentifier | "source-nodandaise"                   |
      | referenceName                 | "referenceProperty"                   |
      | references                    | [{"target":"lady-eleonode-rootford"}] |
    Then the last command should have thrown an exception of type "NodeAggregateIsRoot"

  Scenario: Try to reference a node aggregate of a type not matching the constraints
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                            |
      | sourceNodeAggregateIdentifier | "source-nodandaise"              |
      | referenceName                 | "constrainedReferenceProperty"   |
      | references                    | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "ReferenceCannotBeSet" with code 1648502149

  Scenario: Try to reference a node aggregate which does not cover the source origin
    Given the command CreateNodeAggregateWithNode is executed with payload:
      | Key                           | Value                                               |
      | nodeAggregateIdentifier       | "sir-david-nodenborough"                            |
      | nodeTypeName                  | "Neos.ContentRepository.Testing:NodeWithReferences" |
      | originDimensionSpacePoint     | {"language":"en"}                                   |
      | parentNodeAggregateIdentifier | "lady-eleonode-rootford"                            |
    And the graph projection is fully up to date

    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                             | Value                                 |
      | sourceNodeAggregateIdentifier   | "source-nodandaise"                   |
      | sourceOriginDimensionSpacePoint | {"language": "de"}                    |
      | referenceName                   | "referenceProperty"                   |
      | references                      | [{"target":"sir-david-nodenborough"}] |
    Then the last command should have thrown an exception of type "NodeAggregateDoesCurrentlyNotCoverDimensionSpacePoint"

  # checks for referenceName
  Scenario: Try to reference nodes in an undefined property:
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                            |
      | sourceNodeAggregateIdentifier | "source-nodandaise"              |
      | referenceName                 | "i-do-not-exist"                 |
      | references                    | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "ReferenceCannotBeSet" with code 1618670106

  Scenario: Try to reference nodes in a property that is not of type reference(s):
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                            |
      | sourceNodeAggregateIdentifier | "source-nodandaise"              |
      | referenceName                 | "nonReferenceProperty"           |
      | references                    | [{"target":"anthony-destinode"}] |
    Then the last command should have thrown an exception of type "ReferenceCannotBeSet" with code 1618670106

  Scenario: Try to reference a node aggregate using a property the reference does not declare
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                                                                         |
      | nodeAggregateIdentifier       | "nody-mc-nodeface"                                                            |
      | sourceNodeAggregateIdentifier | "source-nodandaise"                                                           |
      | referenceName                 | "referencePropertyWithProperties"                                             |
      | references                    | [{"target":"anthony-destinode", "properties":{"i-do-not-exist": "whatever"}}] |
    Then the last command should have thrown an exception of type "ReferenceCannotBeSet" with code 1658406662

  Scenario: Try to set a property with a value of a wrong type
    When the command SetNodeReferences is executed with payload and exceptions are caught:
      | Key                           | Value                                                                                          |
      | nodeAggregateIdentifier       | "nody-mc-nodeface"                                                                             |
      | sourceNodeAggregateIdentifier | "source-nodandaise"                                                                            |
      | referenceName                 | "referencePropertyWithProperties"                                                              |
      | references                    | [{"target":"anthony-destinode", "properties":{"postalAddress": "28 31st of February Street"}}] |
    Then the last command should have thrown an exception of type "ReferenceCannotBeSet" with code 1658406762