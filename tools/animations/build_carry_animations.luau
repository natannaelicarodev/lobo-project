-- Builds the carry animations as KeyframeSequences. Run in Roblox Studio (Command Bar
-- or the MCP execute_luau tool, Edit mode). It (re)creates:
--   ReplicatedStorage.AnimationSources.<Name>   used for Studio preview before publishing
--   Workspace.AnimationRig_Wolf.AnimSaves.<Name> open these in the Animation Editor to
--                                                  tweak and "Publish to Roblox"
-- Poses are rotations relative to the rig's rest pose (T-pose; joint axes = world axes:
-- X right, Y up, -Z forward). Joint -> Pose name: the joint's Part1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local function R(x: number?, y: number?, z: number?): CFrame
	return CFrame.Angles(math.rad(x or 0), math.rad(y or 0), math.rad(z or 0))
end

local HIERARCHY = {
	HumanoidRootPart = { "LowerTorso" },
	LowerTorso = { "UpperTorso", "LeftUpperLeg", "RightUpperLeg" },
	UpperTorso = { "Head", "LeftUpperArm", "RightUpperArm" },
	LeftUpperArm = { "LeftLowerArm" },
	LeftLowerArm = { "LeftHand" },
	RightUpperArm = { "RightLowerArm" },
	RightLowerArm = { "RightHand" },
	LeftUpperLeg = { "LeftLowerLeg" },
	LeftLowerLeg = { "LeftFoot" },
	RightUpperLeg = { "RightLowerLeg" },
	RightLowerLeg = { "RightFoot" },
}

-- Every joint gets a pose in every keyframe (identity when not listed), so these
-- animations fully override the default ones while they play: no mixed limbs.
local function keyframe(time: number, poses: { [string]: CFrame }): Keyframe
	local frame = Instance.new("Keyframe")
	frame.Time = time
	local function add(name: string, parent: Instance)
		local pose = Instance.new("Pose")
		pose.Name = name
		pose.CFrame = poses[name] or CFrame.identity
		pose.Weight = 1
		pose.EasingStyle = Enum.PoseEasingStyle.Cubic
		pose.EasingDirection = Enum.PoseEasingDirection.InOut
		pose.Parent = parent
		for _, child in HIERARCHY[name] or {} do
			add(child, pose)
		end
	end
	add("HumanoidRootPart", frame)
	return frame
end

local function merge(base: { [string]: CFrame }, extra: { [string]: CFrame }): { [string]: CFrame }
	local result = table.clone(base)
	for name, value in extra do
		result[name] = value
	end
	return result
end

-- Arms under the box, slight lean back for the weight, head looking a bit down.
local HOLD = {
	UpperTorso = R(4, 0, 0),
	Head = R(-6, 0, 0),
	RightUpperArm = R(0, 60, 0) * R(0, 0, -40),
	LeftUpperArm = R(0, -60, 0) * R(0, 0, 40),
	RightLowerArm = R(0, 35, 0),
	LeftLowerArm = R(0, -35, 0),
	RightHand = R(0, 0, 20),
	LeftHand = R(0, 0, -20),
}

-- Walk step: one leg forward (+X rotation at the hip), the other back with bent knee.
local function stride(forwardLeg: string, backLeg: string, twist: number): { [string]: CFrame }
	return merge(HOLD, {
		LowerTorso = CFrame.new(0, -0.05, 0),
		UpperTorso = R(4, twist, 0),
		[forwardLeg .. "UpperLeg"] = R(22, 0, 0),
		[forwardLeg .. "LowerLeg"] = R(-8, 0, 0),
		[forwardLeg .. "Foot"] = R(-12, 0, 0),
		[backLeg .. "UpperLeg"] = R(-22, 0, 0),
		[backLeg .. "LowerLeg"] = R(-25, 0, 0),
		[backLeg .. "Foot"] = R(15, 0, 0),
	})
end
local PASSING = merge(HOLD, {
	LowerTorso = CFrame.new(0, 0.04, 0),
	RightLowerLeg = R(-18, 0, 0),
	LeftLowerLeg = R(-18, 0, 0),
})

local CROUCH = {
	LowerTorso = CFrame.new(0, -0.7, 0),
	UpperTorso = R(-25, 0, 0),
	Head = R(10, 0, 0),
	RightUpperLeg = R(55, 0, 0),
	LeftUpperLeg = R(55, 0, 0),
	RightLowerLeg = R(-80, 0, 0),
	LeftLowerLeg = R(-80, 0, 0),
	RightFoot = R(25, 0, 0),
	LeftFoot = R(25, 0, 0),
	RightUpperArm = R(0, 60, 0) * R(0, 0, -75),
	LeftUpperArm = R(0, -60, 0) * R(0, 0, 75),
	RightLowerArm = R(0, 15, 0),
	LeftLowerArm = R(0, -15, 0),
}

local REACH_SHELF = merge(HOLD, {
	LowerTorso = CFrame.new(0, -0.15, 0),
	UpperTorso = R(-20, 0, 0),
	Head = R(5, 0, 0),
	RightUpperArm = R(0, 70, 0) * R(0, 0, -15),
	LeftUpperArm = R(0, -70, 0) * R(0, 0, 15),
	RightLowerArm = R(0, 10, 0),
	LeftLowerArm = R(0, -10, 0),
	RightUpperLeg = R(15, 0, 0),
	LeftUpperLeg = R(15, 0, 0),
	RightLowerLeg = R(-20, 0, 0),
	LeftLowerLeg = R(-20, 0, 0),
})

local DEFINITIONS = {
	{
		name = "CarryIdle",
		loop = true,
		priority = Enum.AnimationPriority.Action,
		frames = {
			{ 0, HOLD },
			{ 1, merge(HOLD, { UpperTorso = R(5.5, 0, 0), LowerTorso = CFrame.new(0, -0.03, 0) }) },
			{ 2, HOLD },
		},
	},
	{
		name = "CarryWalk",
		loop = true,
		priority = Enum.AnimationPriority.Action,
		frames = {
			{ 0, stride("Right", "Left", 3) },
			{ 0.225, PASSING },
			{ 0.45, stride("Left", "Right", -3) },
			{ 0.675, PASSING },
			{ 0.9, stride("Right", "Left", 3) },
		},
	},
	{
		name = "PickUp",
		loop = false,
		priority = Enum.AnimationPriority.Action2,
		-- starts already crouched (the box is welded to the hand as soon as the server
		-- accepts, so the hand must begin near the floor where the box was), then lifts
		frames = {
			{ 0, CROUCH },
			{ 0.2, CROUCH },
			{ 0.75, HOLD },
		},
	},
	{
		name = "PlaceBox",
		loop = false,
		priority = Enum.AnimationPriority.Action2,
		frames = {
			{ 0, HOLD },
			{ 0.4, REACH_SHELF },
			{ 0.55, REACH_SHELF },
			{ 0.9, HOLD },
		},
	},
}

local function build(definition): KeyframeSequence
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = definition.name
	sequence.Loop = definition.loop
	sequence.Priority = definition.priority
	for _, frame in definition.frames do
		keyframe(frame[1], frame[2]).Parent = sequence
	end
	return sequence
end

-- Studio preview copies
local sources = ReplicatedStorage:FindFirstChild("AnimationSources")
if sources then
	sources:Destroy()
end
sources = Instance.new("Folder")
sources.Name = "AnimationSources"
for _, definition in DEFINITIONS do
	build(definition).Parent = sources
end
sources.Parent = ReplicatedStorage

-- Rig for the Animation Editor (a copy of the real character, never played)
local oldRig = workspace:FindFirstChild("AnimationRig_Wolf")
if oldRig then
	oldRig:Destroy()
end
local rig = StarterPlayer:FindFirstChild("StarterCharacter"):Clone()
rig.Name = "AnimationRig_Wolf"
rig:SetAttribute("Provisional", true)
local animate = rig:FindFirstChild("Animate")
if animate then
	animate:Destroy()
end
rig.HumanoidRootPart.Anchored = true
rig:PivotTo(CFrame.new(-20, rig:GetExtentsSize().Y / 2, 10))
local saves = Instance.new("Model")
saves.Name = "AnimSaves"
for _, definition in DEFINITIONS do
	build(definition).Parent = saves
end
saves.Parent = rig
rig.Parent = workspace

return `built {#DEFINITIONS} animations`
