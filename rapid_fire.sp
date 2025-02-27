#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
    name = "Ultra Rapid Fire Plugin",
    author = "zetsr",
    description = "Allows players to shoot with almost no cooldown in CSGO",
    version = "1.1",
    url = "https://github.com/zetsr"
};

// 检查武器是否为枪械（不是投掷物或 C4）
bool IsFirearm(int weapon)
{
    char weaponClass[64];
    GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
    if (StrContains(weaponClass, "weapon_") == 0 &&        // 以 "weapon_" 开头
        StrContains(weaponClass, "grenade") == -1 &&      // 不包含 "grenade"
        !StrEqual(weaponClass, "weapon_c4"))              // 不等于 "weapon_c4"
    {
        return true;
    }
    return false;
}

// 检查是否应该移除副攻击冷却（仅对 R8 左轮和匕首）
bool ShouldRemoveSecondaryCooldown(int weapon)
{
    char weaponClass[64];
    GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
    if (StrEqual(weaponClass, "weapon_revolver") ||       // R8 左轮手枪
        StrEqual(weaponClass, "weapon_knife"))            // 匕首
    {
        return true;
    }
    return false;
}

// 封装快速射击逻辑
void ApplyRapidFire(int weapon)
{
    if (!IsFirearm(weapon))
        return;

    int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
    if (clip <= 0)
        return;

    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0);

    if (ShouldRemoveSecondaryCooldown(weapon))
    {
        SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", 0);
    }
}

public void OnPluginStart()
{
    PrintToServer("Ultra Rapid Fire Plugin Loaded!");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUsePost, OnWeaponCanUsePost);
}

public void OnGameFrame()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
            continue;

        int weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
        if (weapon == -1 || !IsValidEntity(weapon))
            continue;

        ApplyRapidFire(weapon);
    }
}

public void OnWeaponCanUsePost(int client, int weapon)
{
    if (!IsPlayerAlive(client))
        return;

    ApplyRapidFire(weapon);
}