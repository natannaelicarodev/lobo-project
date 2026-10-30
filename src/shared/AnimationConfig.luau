--!strict
-- Character animations used by CharacterAnimationController.
-- AnimationId stays "" until the animation is published from the Animation Editor
-- ("Publish to Roblox") — never put an ID here that was not published for this game.
-- While an ID is empty, Studio playtests use the KeyframeSequence with the same name in
-- ReplicatedStorage.AnimationSources (temporary, only works inside Studio).

local AnimationConfig = {}

export type AnimationDefinition = {
	AnimationId: string,
	Priority: Enum.AnimationPriority,
	Looped: boolean,
	FadeTime: number,
}

AnimationConfig.Animations = {
	-- Action: above the default idle/walk (Core/Movement), so arms stay on the box
	CarryIdle = { AnimationId = "rbxassetid://95929208934414", Priority = Enum.AnimationPriority.Action, Looped = true, FadeTime = 0.2 },
	CarryWalk = { AnimationId = "rbxassetid://134787024206171", Priority = Enum.AnimationPriority.Action, Looped = true, FadeTime = 0.2 },
	-- Action2: one-shots that play over the carry loops and then hand back to them
	-- longer fade-in: the crouch at the start of PickUp is reached smoothly
	PickUp = { AnimationId = "rbxassetid://111667969637663", Priority = Enum.AnimationPriority.Action2, Looped = false, FadeTime = 0.25 },
	PlaceBox = { AnimationId = "rbxassetid://84980375964126", Priority = Enum.AnimationPriority.Action2, Looped = false, FadeTime = 0.1 },
} :: { [string]: AnimationDefinition }

-- Humanoid.Running speed above this counts as walking.
AnimationConfig.WalkSpeedThreshold = 0.5

AnimationConfig.StudioPreviewFolder = "AnimationSources"

return AnimationConfig
