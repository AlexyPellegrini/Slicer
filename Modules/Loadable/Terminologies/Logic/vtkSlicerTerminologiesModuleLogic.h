/*==============================================================================

  Program: 3D Slicer

  Copyright (c) Laboratory for Percutaneous Surgery (PerkLab)
  Queen's University, Kingston, ON, Canada. All Rights Reserved.

  See COPYRIGHT.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  This file was originally developed by Csaba Pinter, PerkLab, Queen's University
  and was supported through the Applied Cancer Research Unit program of Cancer Care
  Ontario with funds provided by the Ontario Ministry of Health and Long-Term Care

==============================================================================*/

#ifndef __vtkSlicerTerminologiesModuleLogic_h
#define __vtkSlicerTerminologiesModuleLogic_h

// Slicer includes
#include "vtkSlicerModuleLogic.h"

#include "vtkSlicerTerminologiesModuleLogicModule.h"

#include <vtkVector.h>

class vtkCodedEntry;
class vtkSegment;
class vtkStringArray;
class vtkSlicerTerminologyEntry;
class vtkSlicerTerminologyCategory;
class vtkSlicerTerminologyType;

class VTK_SLICER_TERMINOLOGIES_LOGIC_EXPORT vtkSlicerTerminologiesModuleLogic :
  public vtkSlicerModuleLogic
{
public:
  static vtkSlicerTerminologiesModuleLogic *New();
  vtkTypeMacro(vtkSlicerTerminologiesModuleLogic, vtkSlicerModuleLogic);
  void PrintSelf(ostream& os, vtkIndent indent) override;

  /// Information needed to uniquely identify a terminology code
  class CodeIdentifier
  {
    public:
      CodeIdentifier()
        { };
      CodeIdentifier(std::string codingSchemeDesignator, std::string codeValue, std::string codeMeaning=std::string())
        : CodingSchemeDesignator(codingSchemeDesignator)
        , CodeValue(codeValue)
        , CodeMeaning(codeMeaning)
        { };
      std::string CodingSchemeDesignator;
      std::string CodeValue;
      std::string CodeMeaning; // Human readable name (not required for ID)
  };

  /// Node attribute name for name auto generated
  static const char* GetNameAutoGeneratedAttributeName() { return "Terminologies.AutoUpdateNodeName"; };
  /// Node attribute name for color auto generated
  static const char* GetColorAutoGeneratedAttributeName() { return "Terminologies.AutoUpdateNodeColor"; };

  /// Load terminology or anatomic context from JSON file.
  /// Note: Separate generic loader function was created so that the file does not need to be loaded twice in case
  ///       the type of the context in the JSON file is not known
  /// \param filePath File containing the context to load
  /// \return Success flag
  bool LoadContextFromFile(std::string filePath);
  /// Load terminology dictionary from JSON terminology context file into \sa LoadedTerminologies.
  /// \param filePath File containing the terminology to load
  /// \return Context name (SegmentationCategoryTypeContextName) of the loaded terminology. Empty string on failure.
  std::string LoadTerminologyFromFile(std::string filePath);
  /// Load anatomic context dictionaries from JSON into \sa LoadedAnatomicContexts
  /// \param filePath File containing the anatomic context to load
  /// \return Context name (AnatomicContextName) of the loaded anatomic context. Empty string on failure.
  std::string LoadAnatomicContextFromFile(std::string filePath);
  /// Load terminology dictionary from segmentation descriptor JSON file into \sa LoadedTerminologies.
  /// \param Terminology context name (the descriptor file does not contain information about that)
  /// \param filePath File containing the terminology to load
  /// \return Success flag
  bool LoadTerminologyFromSegmentDescriptorFile(std::string contextName, std::string filePath);
  /// Load anatomic context dictionary from segmentation descriptor JSON file into \sa LoadedAnatomicContexts.
  /// See also \sa LoadTerminologyFromSegmentDescriptorFile
  bool LoadAnatomicContextFromSegmentDescriptorFile(std::string contextName, std::string filePath);

  /// Get context names of loaded terminologies
  void GetLoadedTerminologyNames(std::vector<std::string> &terminologyNames);
  /// Python accessor variant of \sa GetLoadedTerminologyNames
  void GetLoadedTerminologyNames(vtkStringArray* terminologyNames);
  /// Get context names of loaded anatomic contexts
  void GetLoadedAnatomicContextNames(std::vector<std::string> &anatomicContextNames);
  /// Python accessor variant of \sa GetLoadedAnatomicContextNames
  void GetLoadedAnatomicContextNames(vtkStringArray* anatomicContextNames);

  /// Get terminology categories from a terminology as collection of \sa vtkSlicerTerminologyCategory container objects
  /// \param categories Output argument containing all the \sa vtkSlicerTerminologyCategory objects created
  ///   from the categories found in the given terminology
  /// \return Success flag
  bool GetCategoriesInTerminology(std::string terminologyName, std::vector<CodeIdentifier>& categories);
  /// Find category names (codeMeaning) in terminology containing a given string
  /// \param categories Output argument containing all the \sa vtkSlicerTerminologyCategory objects created
  ///   from the categories found in the given terminology
  /// \return Success flag
  bool FindCategoriesInTerminology(std::string terminologyName, std::vector<CodeIdentifier>& categories, std::string search);

  /// Return collection of vtkSlicerTerminologyEntry objects designated by the given codes.
  /// \param preferredTerminologyNames List of terminology names in order of preference. If an empty list is provided then all terminologies are searched.
  std::vector<std::string> FindTerminologyNames(
    std::string categoryCodingSchemeDesignator, std::string categoryCodeValue,
    std::string typeCodingSchemeDesignator, std::string typeCodeValue,
    std::string typeModifierCodingSchemeDesignator, std::string typeModifierCodeValue,
    std::vector<std::string> preferredTerminologyNames,
    vtkCollection* foundEntries=nullptr);

  /// Return list of anatomic context names containing the specified anatomic region.
  /// \param preferredAnatomicContextNames List of anatomic context names in order of preference. If an empty list is provided then all context are searched.
  std::vector<std::string> FindAnatomicContextNames(
    std::string anatomicRegionCodingSchemeDesignator, std::string anatomicRegionCodeValue,
    std::string anatomicRegionModifierCodingSchemeDesignator, std::string anatomicRegionModifierCodeValue,
    std::vector<std::string> preferredAnatomicContextNames,
    vtkCollection* foundEntries=nullptr);

  /// Get a category with given name from a terminology
  /// \param category Output argument containing the details of the found category if any (if return value is true)
  /// \return Success flag
  bool GetCategoryInTerminology(std::string terminologyName, CodeIdentifier categoryId, vtkSlicerTerminologyCategory* categoryObject);
  /// Get number of categories in a terminology
  int GetNumberOfCategoriesInTerminology(std::string terminologyName);
  /// Get a category from a terminology by index.
  /// \param categoryIndex specifies which category to return
  /// \param category category is returned in this object
  /// \return Success flag
  bool GetNthCategoryInTerminology(std::string terminologyName, int categoryIndex, vtkSlicerTerminologyCategory* category);

  /// Get terminology types from a terminology category as collection of \sa vtkSlicerTerminologyType container objects
  /// \param types Output argument containing all the \sa vtkSlicerTerminologyType objects created
  ///   from the types found in the given terminology category
  /// \return Success flag
  bool GetTypesInTerminologyCategory(std::string terminologyName, CodeIdentifier categoryId, std::vector<CodeIdentifier>& types);
  /// Get terminology types from a terminology category as collection of \sa vtkSlicerTerminologyType container objects
  /// \param types Output argument containing all the \sa type IDs in the category.
  ///   from the types found in the given terminology category
  /// \param typeObjects Output argument containing all the \sa type objects in the category.. This is useful if type objects
  ///   need to be retrieved for a large number of types, because it avoids the need to do a costly search in the json tree.
  /// \return Success flag
  bool FindTypesInTerminologyCategory(std::string terminologyName, CodeIdentifier categoryId, std::vector<CodeIdentifier>& types, std::string search,
    std::vector<vtkSmartPointer<vtkSlicerTerminologyType>>* typeObjects=nullptr);
  /// Get a type with given name from a terminology category
  /// \param type Output argument containing the details of the found type if any (if return value is true)
  /// \return Success flag
  bool GetTypeInTerminologyCategory(std::string terminologyName, CodeIdentifier categoryId, CodeIdentifier typeId, vtkSlicerTerminologyType* typeObject);
  /// Get number of types in the chosen category in a terminology
  int GetNumberOfTypesInTerminologyCategory(std::string terminologyName, vtkSlicerTerminologyCategory* category);
  /// Get a terminology type by index
  /// \param terminologyName input terminology name
  /// \param category input category
  /// \param typeIndex index of type to return
  /// \param typeObject output type
  /// \return Success flag
  bool GetNthTypeInTerminologyCategory(std::string terminologyName, vtkSlicerTerminologyCategory* category, int typeIndex, vtkSlicerTerminologyType* type);

  /// Get terminology type modifiers from a terminology type as collection of \sa vtkSlicerTerminologyType container objects
  /// \param typeModifierCollection Output argument containing all the \sa vtkSlicerTerminologyType objects created
  ///   from the type modifiers found in the given terminology type
  /// \return Success flag
  bool GetTypeModifiersInTerminologyType(std::string terminologyName, CodeIdentifier categoryId, CodeIdentifier typeId, std::vector<CodeIdentifier>& typeModifiers);
  /// Get a type modifier with given name from a terminology type
  /// \param typeModifier Output argument containing the details of the found type modifier if any (if return value is true)
  /// \return Success flag
  bool GetTypeModifierInTerminologyType(std::string terminologyName,
    CodeIdentifier categoryId, CodeIdentifier typeId, CodeIdentifier modifierId, vtkSlicerTerminologyType* typeModifier);
  /// Get number of type modifiers for the chosen category and type in a terminology
  int GetNumberOfTypeModifiersInTerminologyType(std::string terminologyName, vtkSlicerTerminologyCategory* category, vtkSlicerTerminologyType* type);
  /// Get a terminology type by index
  /// \param terminologyName input terminology name
  /// \param category input category
  /// \param typeObject input type
  /// \param typeModifierIndex index of type modifier to return
  /// \param typeModifier output type modifier
  /// \return Success flag
  bool GetNthTypeModifierInTerminologyType(std::string terminologyName, vtkSlicerTerminologyCategory* category, vtkSlicerTerminologyType* type, int typeModifierIndex, vtkSlicerTerminologyType* typeModifier);

  /// Get anatomic regions from an anatomic context as collection of \sa vtkSlicerTerminologyType container objects
  /// \param regionCollection Output argument containing all the \sa vtkSlicerTerminologyType objects created
  ///   from the regions found in the given anatomic context
  /// \return Success flag
  bool GetRegionsInAnatomicContext(std::string anatomicContextName, std::vector<CodeIdentifier>& regions);
  /// Get number of anatomic regions in anatomic context.
  /// Allows iterating through all anatomic regions in Python.
  int GetNumberOfRegionsInAnatomicContext(std::string anatomicContextName);
  /// Get anatomic region by index.
  /// Allows iterating through all anatomic regions in Python.
  /// \param anatomicContextName anatomic context name
  /// \param regionIndex index of region to return, must be between 0 and GetNumberOfRegionsInAnatomicContext(...)-1
  /// \param regionObject found anatomical region
  /// \return Success flag
  bool GetNthRegionInAnatomicContext(std::string anatomicContextName, int regionIndex, vtkSlicerTerminologyType* regionObject);

  /// Get all region names (codeMeaning) in an anatomic context
  /// \return Success flag
  bool FindRegionsInAnatomicContext(std::string anatomicContextName, std::vector<CodeIdentifier>& regions, std::string search);
  /// Get a region with given name from an anatomic context
  /// \param region Output argument containing the details of the found region if any (if return value is true)
  /// \return Success flag
  bool GetRegionInAnatomicContext(std::string anatomicContextName, CodeIdentifier regionId, vtkSlicerTerminologyType* regionObject);

  /// Get region modifiers from an anatomic region as collection of \sa vtkSlicerTerminologyType container objects
  /// \param regionModifierCollection Output argument containing all the \sa vtkSlicerTerminologyType objects created
  ///   from the region modifiers found in the given anatomic region
  /// \return Success flag
  bool GetRegionModifiersInAnatomicRegion(std::string anatomicContextName, CodeIdentifier regionId, std::vector<CodeIdentifier>& regionModifiers);
  /// Get a region modifier with given name from an anatomic region
  /// \param regionModifier Output argument containing the details of the found region modifier if any (if return value is true)
  /// \return Success flag
  bool GetRegionModifierInAnatomicRegion(std::string anatomicContextName,
    CodeIdentifier regionId, CodeIdentifier modifierId, vtkSlicerTerminologyType* regionModifier);
  /// Get number of anatomic regions in anatomic context.
  /// Allows iterating through anatomic region modifiers in Python.
  int GetNumberOfRegionModifierInAnatomicRegion(std::string anatomicContextName, vtkSlicerTerminologyType* regionObject);
  /// Get anatomic region by index.
  /// Allows iterating through anatomic region modifiers in Python.
  /// \param anatomicContextName anatomic context name
  /// \param regionObject anatomical region
  /// \param regionModifierIndex index of region to return, must be between 0 and GetNumberOfRegionsInAnatomicContext(...)-1
  /// \param regionModifier found region modifier object
  /// \return Success flag
  bool GetNthRegionModifierInAnatomicRegion(std::string anatomicContextName, vtkSlicerTerminologyType* regionObject,
    int regionModifierIndex, vtkSlicerTerminologyType* regionModifier);

  /// Find terminology type or type modifier based on '3dSlicerLabel' attribute
  /// \param terminologyName Terminology context in which the attribute is looked for
  /// \param slicerLabel Attribute to look for
  /// \param entry Terminology entry populated if the attribute is found
  /// \return Flag indicating whether the attribute was found
  bool FindTypeInTerminologyBy3dSlicerLabel(std::string terminologyName, std::string slicerLabel, vtkSlicerTerminologyEntry* entry);

  /// Convert terminology category object to code identifier
  static CodeIdentifier CodeIdentifierFromTerminologyCategory(vtkSlicerTerminologyCategory* category);
  /// Convert terminology type object to code identifier
  static CodeIdentifier CodeIdentifierFromTerminologyType(vtkSlicerTerminologyType* type);

  /// Convert terminology entry VTK object to string containing identifiers
  /// Serialized terminology entry consists of the following: terminologyContextName, category (codingScheme,
  /// codeValue, codeMeaning triple), type, typeModifier, anatomicContextName, anatomicRegion, anatomicRegionModifier
  static std::string SerializeTerminologyEntry(vtkSlicerTerminologyEntry* entry);

  /// Assemble terminology string from terminology codes
  /// Note: The order of the attributes are inconsistent with the codes used in this class for compatibility reasons
  ///       (to vtkMRMLColorLogic::AddTermToTerminology)
  static std::string SerializeTerminologyEntry(
    std::string terminologyContextName,
    std::string categoryValue, std::string categorySchemeDesignator, std::string categoryMeaning,
    std::string typeValue, std::string typeSchemeDesignator, std::string typeMeaning,
    std::string modifierValue, std::string modifierSchemeDesignator, std::string modifierMeaning,
    std::string anatomicContextName,
    std::string regionValue, std::string regionSchemeDesignator, std::string regionMeaning,
    std::string regionModifierValue, std::string regionModifierSchemeDesignator, std::string regionModifierMeaning );

  /// Populate terminology entry VTK object based on serialized entry
  /// Serialized terminology entry consists of the following: terminologyContextName, category (codingScheme,
  /// codeValue, codeMeaning triple), type, typeModifier, anatomicContextName, anatomicRegion, anatomicRegionModifier
  ///  \return Success flag
  bool DeserializeTerminologyEntry(std::string serializedEntry, vtkSlicerTerminologyEntry* entry);

  /// Assemble human readable info string from a terminology entry, for example for tooltips
  static std::string GetInfoStringFromTerminologyEntry(vtkSlicerTerminologyEntry* entry);

  ///@{
  /// Compare two terminology entries for equality.
  /// \return True if the entries are equal, false otherwise.
  // These functions are not static because in the future conversion may involve translation tables.
  // (that allows comparing of terms between different coding schemes)
  bool AreSegmentTerminologyEntriesEqual(vtkSegment* segment1, vtkSegment* segment2);
  bool AreTerminologyEntriesEqual(vtkSlicerTerminologyEntry* entry1, vtkSlicerTerminologyEntry* entry2);
  bool AreTerminologyEntriesEqual(std::string terminologyEntry1, std::string terminologyEntry2);
  bool AreCodedEntriesEqual(vtkCodedEntry* codedEntry1, vtkCodedEntry* codedEntry2);
  ///@}

public:
  vtkGetStringMacro(UserContextsPath);
  vtkSetStringMacro(UserContextsPath);

protected:
  vtkSlicerTerminologiesModuleLogic();
  ~vtkSlicerTerminologiesModuleLogic() override;

  void SetMRMLSceneInternal(vtkMRMLScene* newScene) override;

  /// Load default terminology dictionaries from JSON into \sa LoadedTerminologies
  void LoadDefaultTerminologies();
  /// Load default anatomic context dictionaries from JSON into \sa LoadedAnatomicContexts
  void LoadDefaultAnatomicContexts();
  /// Load terminologies and anatomic contexts from the user settings directory \sa UserContextsPath
  void LoadUserContexts();

protected:
  /// The path from which the json files are automatically loaded on startup
  char* UserContextsPath{nullptr};

private:
  vtkSlicerTerminologiesModuleLogic(const vtkSlicerTerminologiesModuleLogic&) = delete;
  void operator=(const vtkSlicerTerminologiesModuleLogic&) = delete;

  class vtkInternal;
  vtkInternal* Internal;
  friend class vtkInternal;
};

#endif
