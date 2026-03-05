extends RefCounted
class_name ClaimUtils

const OWNER_NONE := ""
const OWNER_FREYA := "freya"
const OWNER_ENEMY := "enemy"

static func normalized_owner(owner: String) -> String:
	var key = owner.to_lower()
	if key == OWNER_FREYA:
		return OWNER_FREYA
	if key == OWNER_ENEMY:
		return OWNER_ENEMY
	return OWNER_NONE

static func owner_from_entry(entry: Dictionary) -> String:
	var owner = normalized_owner(str(entry.get("claimed_by", OWNER_NONE)))
	if owner != OWNER_NONE:
		return owner
	# Backward-compatible read path for older serialized dictionaries.
	if bool(entry.get("claimed", false)):
		return OWNER_FREYA
	return OWNER_NONE

static func is_claimed(entry: Dictionary) -> bool:
	return owner_from_entry(entry) != OWNER_NONE

static func is_claimed_by(entry: Dictionary, owner: String) -> bool:
	return owner_from_entry(entry) == normalized_owner(owner)

static func apply_owner(entry: Dictionary, owner: String) -> Dictionary:
	var out: Dictionary = entry.duplicate(true)
	var normalized = normalized_owner(owner)
	out["claimed_by"] = normalized
	out["claimed"] = normalized != OWNER_NONE
	out["claim_progress"] = 0.0
	return out
