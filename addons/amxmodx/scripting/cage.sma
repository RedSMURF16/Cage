/*
*
*	Cage by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*   Commands:
*       say /cage [name | all]          "Opens the Cage menu or executes the specified player(s)."
*       say_team /cage [name | all]     "Opens the Cage menu or executes the specified player(s)."
*       say /CAGE_vote                  "Opens the player voting menu."
*       say_team /CAGE_vote             "Opens the player voting menu."
*       CAGE_reload                     "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define CAGE_CHECK                  10.0
#define CAGE_OFFSET_BASE            120.0
#define CAGE_OFFSET_MIN             65.0
#define CAGE_OFFSET_MAX             900.0
#define CAGE_OFFSET_STEP            10.0
#define CAGE_GHOST_ALPHA            120
#define CAGE_ROTATION_STEP          22.5
#define ADMIN_ACCESS                ADMIN_RCON
#define ADMIN_ACCESS_VOTE           ADMIN_USER
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define CAGE_KEY                    222220
#define CAGE_VOTE_KEY               222221
#define CAGE_ARRAY_ITEM             pev_iuser1
#define VIEW_FORWARD_OFFSET         128.0
#define VIEW_RIGHT_OFFSET           64.0
#define VIEW_UP_OFFSET              16.0
#define HUD_Y_STEP                  0.025
#define HUD_Y_MAX                   0.7
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "CAGE_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_CAGE
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_SHOW               = (1 << 0),
    FLAG_GHOST              = (1 << 1),
    FLAG_GROUND             = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_USED               = (1 << 4)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_SOUND_CAGE,
    Array:SETTING_DEFAULT_SOUND_OPEN,
    Array:SETTING_DEFAULT_SOUND_CLOSE,
    Array:SETTING_DEFAULT_MESSAGE,
    Array:SETTING_DEFAULT_MESSAGE_FORCED,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    SETTING_DEFAULT_HOLD_DURATION[2],
    bool:SETTING_PLAY_SOUND_ON_CAGE,
    bool:SETTING_WRITE_MESSAGE_ON_CAGE,
    bool:SETTING_CAGE_ALL_EXCLUDE_CALLER,
    bool:SETTING_STRIP_WEAPONS,
    bool:SETTING_RELEASE_IF_CAGED,
    bool:SETTING_VOTE_ENABLED,
    Float:SETTING_VOTE_COOLDOWN,
    Float:SETTING_VOTE_DURATION,
    Float:SETTING_VOTE_PERCENTAGE,

    Float:SETTING_HUD_X,
    Float:SETTING_HUD_Y,
    SETTING_HUD_COLOR[3],
    SETTING_HUD_EFFECT,
    Float:SETTING_HUD_FXTIME,
    Float:SETTING_HUD_HOLDTIME,
    Float:SETTING_HUD_FADEIN,
    Float:SETTING_HUD_FADEOUT,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],

    bool:SETTING_CAGE_LOAD,
    Float:SETTING_CAGE_TASK,
}

enum _:CAGE
{
    CAGE_ID,
    CAGE_ITEM,
    CAGE_FLAGS,
    CAGE_TEAM,
    CAGE_NAME[MAX_VALUE_LENGTH],

    Float:CAGE_ORIGIN[3],
    Float:CAGE_ANGLES[3],
    Float:CAGE_ORIGIN_CAGE[3],
    Float:CAGE_ORIGIN_RELEASE[3],
    Float:CAGE_ANGLES_RELEASE[3],
    Float:CAGE_MINS[3],
    Float:CAGE_MAXS[3],

    Float:CAGE_NEXT_ACTIVE,
    Float:CAGE_NEXT_OPEN
}

enum _:PLAYER_DATA
{
    PDATA_CAGE_GHOST,
    PDATA_CAGE_MENU,
    bool:PDATA_CAGE_ACTION,
    PDATA_CAGE_ID,
    PDATA_CAGE_USED,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    Float:PDATA_NEXT_CAGE,
    Float:PDATA_NEXT_CHECK
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_CAGE,
    SOUND_OPEN,
    SOUND_CLOSE
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE,
    MENU_VOTE,
    MENU_VOTE_CONFIRM
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate",
    "menuHandlerVote",
    "menuHandlerVoteConfirm",
}

new g_szCN[] = "cage"

new Array:g_aCage,
    Array:g_aCageConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink,
    g_iCage, g_iCageConfig, g_iBarTime, Float:g_iHudCurrentY, g_iHudObject_1, g_iHudObject_2, g_iHudObject_3, g_iHudSlot,
    g_szVoteTarget[MAX_VALUE_LENGTH], g_iVoteTargetUserid, g_iVoteNo, g_iVoteYes, Float:g_fVoteNext,
    g_iMaxPlayers

public plugin_init()
{
    register_plugin("Cage", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_Cage", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /cage",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Cage menu.")
    register_clcmd("say_team /cage",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Cage menu.")
    register_clcmd("say /CAGE_vote",        "cmdVote", ADMIN_ACCESS_VOTE, "-- Opens the player voting menu.")
    register_clcmd("say_team /CAGE_vote",   "cmdVote", ADMIN_ACCESS_VOTE, "-- Opens the player voting menu.")
    register_concmd("CAGE_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("Cage.txt")

    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iBarTime = get_user_msgid("BarTime")
    g_iHudObject_1 = CreateHudSyncObj()
    g_iHudObject_2 = CreateHudSyncObj()
    g_iHudObject_3 = CreateHudSyncObj()
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableCage()

    cageInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aCage = ArrayCreate(CAGE)
    g_aCageConfig = ArrayCreate(CAGE)
    g_eSettings[SETTING_DEFAULT_SOUND_CAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_OPEN] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_CLOSE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aCage)
    ArrayDestroy(g_aCageConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_CAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_OPEN])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])
}

stock cageToggleTarget(id, iTarget)
{
    new eCage[CAGE], iItem
    if ( g_eSettings[SETTING_RELEASE_IF_CAGED]
    && (iItem = cageGet(eCage, g_ePlayerData[iTarget][PDATA_CAGE_ID])) != -1 )
    {
        engfunc(EngFunc_SetOrigin, iTarget, eCage[CAGE_ORIGIN_RELEASE])
        set_pev(iTarget, pev_angles, eCage[CAGE_ANGLES_RELEASE])
        set_pev(iTarget, pev_v_angle, eCage[CAGE_ANGLES_RELEASE])
        set_pev(iTarget, pev_fixangle, 1)
        cageSound(eCage[CAGE_ID], SOUND_CLOSE, false)
        cageSound(iTarget, SOUND_OPEN)

        eCage[CAGE_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aCage, iItem, eCage)
        g_ePlayerData[iTarget][PDATA_CAGE_ID] = 0
        return 1
    }

    for ( iItem = 0; iItem < g_iCage; iItem ++ )
    {
        ArrayGetArray(g_aCage, iItem, eCage)
        if ( eCage[CAGE_FLAGS] & FLAG_USED )
            continue

        cageCage(eCage, iTarget, true)
        ArraySetArray(g_aCage, iItem, eCage)
        return 1
    }

    client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_NO_CAGE")
    return 0
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    new szTarget[64]
    read_argv(2, szTarget, charsmax(szTarget))
    remove_quotes(szTarget)
    if ( !szTarget[0] )
    {
        cageSound(id, SOUND_MENU_NAV)
        cageMenu(id, MENU_ROOT)
        return PLUGIN_HANDLED
    }

    new iArgIndex = 2
    new bool:bProcessed[33]
    while ( szTarget[0] )
    {
        if ( equali(szTarget, "all") )
        {
            for ( new iTarget = 1; iTarget <= g_iMaxPlayers; iTarget ++ )
            {
                if ( !is_user_connected(iTarget) || bProcessed[iTarget]
                || (g_eSettings[SETTING_CAGE_ALL_EXCLUDE_CALLER] && iTarget == id) )
                    continue

                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                    continue

                if ( !cageToggleTarget(id, iTarget) )
                    break
            }
        }
        else
        {
            new iTarget = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF)
            if ( iTarget && !bProcessed[iTarget] )
            {
                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                {
                    client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_NOT_ALIVE")
                }
                else if ( !cageToggleTarget(id, iTarget) )
                {
                    break
                }
            }
        }

        iArgIndex ++
        szTarget[0] = EOS
        read_argv(iArgIndex, szTarget, charsmax(szTarget))
        remove_quotes(szTarget)
    }

    return PLUGIN_HANDLED
}

public cmdVote(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    if ( !g_eSettings[SETTING_VOTE_ENABLED] )
    {
        client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_VOTE_DISABLED")
        return PLUGIN_HANDLED
    }

    if ( task_exists(CAGE_VOTE_KEY)
    || get_gametime() < g_fVoteNext )
    {
        client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_VOTE_COOLDOWN")
        return PLUGIN_HANDLED
    }

    new iAlive
    for ( new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer ++ )
        if ( is_user_alive(iPlayer) )
            iAlive ++

    if ( !iAlive )
    {
        client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_NO_VOTE_TARGETS")
        return PLUGIN_HANDLED
    }

    cageSound(id, SOUND_MENU_NAV)
    cageMenu(id, MENU_VOTE)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    cageReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aCageConfig)
        g_iCageConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/Cage.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eCage[CAGE], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iCageConfig )
                            ArrayPushArray(g_aCageConfig, eCage)

                        copy(eCage[CAGE_NAME], charsmax(eCage[CAGE_NAME]), szData)
                        eCage[CAGE_FLAGS]                     = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eCage[CAGE_TEAM]                      = g_eSettings[SETTING_DEFAULT_TEAM]

                        iSection = SECTION_CAGE
                        g_iCageConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_CAGE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_CAGE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_CAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_OPEN") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_OPEN], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_OPEN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_CLOSE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_CLOSE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE_FORCED") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HOLD_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HOLD_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_HOLD_DURATION]))
                        else if ( equali(szKey, "SETTING_PLAY_SOUND_ON_CAGE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_PLAY_SOUND_ON_CAGE], charsmax(g_eSettings[SETTING_PLAY_SOUND_ON_CAGE]))
                        else if ( equali(szKey, "SETTING_WRITE_MESSAGE_ON_CAGE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_WRITE_MESSAGE_ON_CAGE], charsmax(g_eSettings[SETTING_WRITE_MESSAGE_ON_CAGE]))
                        else if ( equali(szKey, "SETTING_CAGE_ALL_EXCLUDE_CALLER") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CAGE_ALL_EXCLUDE_CALLER], charsmax(g_eSettings[SETTING_CAGE_ALL_EXCLUDE_CALLER]))
                        else if ( equali(szKey, "SETTING_STRIP_WEAPONS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_STRIP_WEAPONS], charsmax(g_eSettings[SETTING_STRIP_WEAPONS]))
                        else if ( equali(szKey, "SETTING_RELEASE_IF_CAGED") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_RELEASE_IF_CAGED], charsmax(g_eSettings[SETTING_RELEASE_IF_CAGED]))
                        else if ( equali(szKey, "SETTING_VOTE_ENABLED") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_ENABLED], charsmax(g_eSettings[SETTING_VOTE_ENABLED]))
                        else if ( equali(szKey, "SETTING_VOTE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_COOLDOWN], charsmax(g_eSettings[SETTING_VOTE_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_VOTE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_DURATION], charsmax(g_eSettings[SETTING_VOTE_DURATION]))
                        else if ( equali(szKey, "SETTING_VOTE_PERCENTAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_PERCENTAGE], charsmax(g_eSettings[SETTING_VOTE_PERCENTAGE]))
                        else if ( equali(szKey, "SETTING_HUD_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_X], charsmax(g_eSettings[SETTING_HUD_X]))
                        else if ( equali(szKey, "SETTING_HUD_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_Y], charsmax(g_eSettings[SETTING_HUD_Y]))
                        else if ( equali(szKey, "SETTING_HUD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_COLOR], charsmax(g_eSettings[SETTING_HUD_COLOR]))
                        else if ( equali(szKey, "SETTING_HUD_EFFECT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_EFFECT], charsmax(g_eSettings[SETTING_HUD_EFFECT]))
                        else if ( equali(szKey, "SETTING_HUD_FXTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FXTIME], charsmax(g_eSettings[SETTING_HUD_FXTIME]))
                        else if ( equali(szKey, "SETTING_HUD_HOLDTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_HOLDTIME], charsmax(g_eSettings[SETTING_HUD_HOLDTIME]))
                        else if ( equali(szKey, "SETTING_HUD_FADEIN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEIN], charsmax(g_eSettings[SETTING_HUD_FADEIN]))
                        else if ( equali(szKey, "SETTING_HUD_FADEOUT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEOUT], charsmax(g_eSettings[SETTING_HUD_FADEOUT]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_CAGE_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CAGE_LOAD], charsmax(g_eSettings[SETTING_CAGE_LOAD]))
                        else if ( equali(szKey, "SETTING_CAGE_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_CAGE_TASK], charsmax(g_eSettings[SETTING_CAGE_TASK]))
                    }
                    case SECTION_CAGE:
                    {
                        if ( equali(szKey, "CAGE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCage[CAGE_TEAM], charsmax(eCage[CAGE_TEAM]))
                    }
                }
            }
        }
    }

    if ( g_iCageConfig )
        ArrayPushArray(g_aCageConfig, eCage)
    else
        set_fail_state("No Cages were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eCage[CAGE], iItem
    if ( g_ePlayerData[id][PDATA_CAGE_GHOST]
    && (iItem = cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_GHOST])) != -1 )
    {
        cageKill(eCage[CAGE_ID])
        cageRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_CAGE_GHOST]  = 0
    g_ePlayerData[id][PDATA_CAGE_MENU]   = 0
}

stock cageInit()
{
    g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
    if ( g_eSettings[SETTING_CAGE_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock cageMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "CAGE_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_ROTATE"); }
        case MENU_VOTE:             { menuVote(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_VOTE"); }
        case MENU_VOTE_CONFIRM:     { menuVoteConfirm(id, iMenu);   format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_ROOT_VOTE_CONFIRM", g_szVoteTarget); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAGE_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "CAGE_ON" : "CAGE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "CAGE_ON" : "CAGE_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iCage >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_LIMIT", MAX_ENT)

                cageSound(id, SOUND_MENU_REMOVE)
                cageMenu(id, MENU_ROOT)
            }
            else
            {
                cageSound(id, SOUND_MENU_NAV)
                cageMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iCage )
            {
                client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_NO_CAGE")

                cageSound(id, SOUND_MENU_REMOVE)
                cageMenu(id, MENU_ROOT)
            }
            else
            {
                cageSound(id, SOUND_MENU_NAV)
                cageMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iCage )
            {
                client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_NO_CAGE")

                cageSound(id, SOUND_MENU_REMOVE)
                cageMenu(id, MENU_ROOT)
            }
            else
            {
                cageSound(id, SOUND_MENU_REMOVE)
                cageMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            cageNoClip(id)
        }
        case ROOT_GODMODE:
        {
            cageGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eCage[CAGE], szItem[64]
    for ( new i = 0; i < g_iCageConfig; i ++ )
    {
        ArrayGetArray(g_aCageConfig, i, eCage)

        copy(szItem, charsmax(szItem), eCage[CAGE_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        cageSound(id, SOUND_MENU_NAV)
        cageMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    cageCreate(id, item)
    cageSound(id, SOUND_MENU_NAV)
    cageMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eCage[CAGE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_REMOVE_CURRENT", eCage[CAGE_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    cageSelect(eCage, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
}

public menuHandlerRemove(id, menu, item)
{
    new eCage[CAGE]
    ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        cageSelect(eCage, eCage[CAGE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAGE_MENU] >= g_iCage - 1 )
                g_ePlayerData[id][PDATA_CAGE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAGE_MENU] ++

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAGE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAGE_MENU] = g_iCage - 1
            else
                g_ePlayerData[id][PDATA_CAGE_MENU] --

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eCage[CAGE_FLAGS] &= ~FLAG_ACTIVE
            cageSetState(eCage)
            cageKill(eCage[CAGE_ID])
            cageRemove(g_ePlayerData[id][PDATA_CAGE_MENU])

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_REMOVE_CURRENT", eCage[CAGE_NAME])
            g_ePlayerData[id][PDATA_CAGE_MENU] = 0

            cageSound(id, g_iCage > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            cageMenu(id, g_iCage > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iCage )
            {
                ArrayGetArray(g_aCage, 0, eCage)
                eCage[CAGE_FLAGS] &= ~FLAG_ACTIVE

                cageSetState(eCage)
                cageKill(eCage[CAGE_ID])
                cageRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_CAGE_MENU] = 0

            cageSound(id, SOUND_MENU_ALERT)
            cageMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                cageSound(id, SOUND_MENU_NAV)
                cageMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAGE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAGE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eCage[CAGE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_SHOW_CURRENT",
    eCage[CAGE_FLAGS] & FLAG_SHOW ? "\y" : "\r", eCage[CAGE_NAME], id, eCage[CAGE_FLAGS] & FLAG_SHOW ? "CAGE_SHOWN" : "CAGE_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    cageSelect(eCage, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
}

public menuHandlerShow(id, menu, item)
{
    new eCage[CAGE]
    ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        cageSelect(eCage, eCage[CAGE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAGE_MENU] >= g_iCage - 1 )
                g_ePlayerData[id][PDATA_CAGE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAGE_MENU] ++

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAGE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAGE_MENU] = g_iCage - 1
            else
                g_ePlayerData[id][PDATA_CAGE_MENU] --

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eCage[CAGE_FLAGS] ^= FLAG_SHOW
            if ( eCage[CAGE_FLAGS] & FLAG_SHOW )
                eCage[CAGE_FLAGS] |= FLAG_ACTIVE
            else
                eCage[CAGE_FLAGS] &= ~FLAG_ACTIVE
            cageSetState(eCage)

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_SHOW_CURRENT",
            eCage[CAGE_NAME], id, eCage[CAGE_FLAGS] & FLAG_SHOW ? "CAGE_CHAT_SHOWN" : "CAGE_CHAT_HIDDEN")
            ArraySetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iCage; i ++ )
            {
                ArrayGetArray(g_aCage, i, eCage)
                eCage[CAGE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                cageSetState(eCage)

                ArraySetArray(g_aCage, i, eCage)
            }

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_SHOW_ALL_SHOWN")
            cageSound(id, SOUND_MENU_ALERT)
            cageMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iCage; i ++ )
            {
                ArrayGetArray(g_aCage, i, eCage)
                eCage[CAGE_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                cageSetState(eCage)

                ArraySetArray(g_aCage, i, eCage)
            }

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_SHOW_ALL_HIDDEN")
            cageSound(id, SOUND_MENU_ALERT)
            cageMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                cageSound(id, SOUND_MENU_NAV)
                cageMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAGE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAGE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eCage[CAGE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_STATUS_CURRENT",
    eCage[CAGE_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eCage[CAGE_NAME], id, eCage[CAGE_FLAGS] & FLAG_ACTIVE ? "CAGE_ENABLED" : "CAGE_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    cageSelect(eCage, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
}

public menuHandlerStatus(id, menu, item)
{
    new eCage[CAGE]
    ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        cageSelect(eCage, eCage[CAGE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAGE_MENU] >= g_iCage - 1 )
                g_ePlayerData[id][PDATA_CAGE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAGE_MENU] ++

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAGE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAGE_MENU] = g_iCage - 1
            else
                g_ePlayerData[id][PDATA_CAGE_MENU] --

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eCage[CAGE_FLAGS] ^= FLAG_ACTIVE
            cageSetState(eCage)

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_STATUS_CURRENT",
            eCage[CAGE_NAME], id, eCage[CAGE_FLAGS] & FLAG_ACTIVE ? "CAGE_CHAT_ENABLED" : "CAGE_CHAT_DISABLED")
            ArraySetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iCage; i ++ )
            {
                ArrayGetArray(g_aCage, i, eCage)
                eCage[CAGE_FLAGS] |= FLAG_ACTIVE
                cageSetState(eCage)

                ArraySetArray(g_aCage, i, eCage)
            }

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_STATUS_ALL_ENABLED")
            cageSound(id, SOUND_MENU_ALERT)
            cageMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iCage; i ++ )
            {
                ArrayGetArray(g_aCage, i, eCage)
                eCage[CAGE_FLAGS] &= ~FLAG_ACTIVE
                cageSetState(eCage)

                ArraySetArray(g_aCage, i, eCage)
            }

            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_STATUS_ALL_DISABLED")
            cageSound(id, SOUND_MENU_ALERT)
            cageMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                cageSound(id, SOUND_MENU_NAV)
                cageMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAGE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAGE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eCage[CAGE]
    if ( cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROTATE_GROUND",
    id, eCage[CAGE_FLAGS] & FLAG_GROUND ? "CAGE_ON" : "CAGE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eCage[CAGE], iItem
    if ( (iItem = cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eCage[CAGE_ID], pev_angles, eCage[CAGE_ANGLES])
            eCage[CAGE_ANGLES][1] -= CAGE_ROTATION_STEP
            if ( eCage[CAGE_ANGLES][1] < -180.0 ) eCage[CAGE_ANGLES][1] += 360.0

            set_pev(eCage[CAGE_ID], pev_angles, eCage[CAGE_ANGLES])
            ArraySetArray(g_aCage, iItem, eCage)

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eCage[CAGE_ID], pev_angles, eCage[CAGE_ANGLES])
            eCage[CAGE_ANGLES][1] += CAGE_ROTATION_STEP
            if ( eCage[CAGE_ANGLES][1] > 180.0 ) eCage[CAGE_ANGLES][1] -= 360.0

            set_pev(eCage[CAGE_ID], pev_angles, eCage[CAGE_ANGLES])
            ArraySetArray(g_aCage, iItem, eCage)

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eCage[CAGE_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aCage, iItem, eCage)

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            cageTrace(eCage, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAGE_GHOST] = 0

            eCage[CAGE_FLAGS] &= ~FLAG_GHOST
            eCage[CAGE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eCage[CAGE_ANGLES][0] = -eCage[CAGE_ANGLES][0]
            cageSetSize(eCage)
            cageSetState(eCage)
            client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_CREATE_NEW", eCage[CAGE_NAME])

            ArraySetArray(g_aCage, iItem, eCage)
            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            cageKill(eCage[CAGE_ID])
            cageRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAGE_GHOST] = 0

            cageSound(id, SOUND_MENU_NAV)
            cageMenu(id, MENU_CREATE)
        }
        default:
        {
            cageKill(eCage[CAGE_ID])
            cageRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAGE_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuVote(id, iMenu)
{
    new szName[MAX_NAME_LENGTH], szInfo[8]
    for ( new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer ++ )
    {
        if ( !is_user_alive(iPlayer) )
            continue

        get_user_name(iPlayer, szName, charsmax(szName))
        num_to_str(get_user_userid(iPlayer), szInfo, charsmax(szInfo))
        menu_additem(iMenu, szName, szInfo)
    }

    return PLUGIN_HANDLED
}

public menuHandlerVote(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new szInfo[8]
    menu_item_getinfo(menu, item, _, szInfo, charsmax(szInfo))

    new iUserid = str_to_num(szInfo)
    new iPlayer = find_player("k", iUserid)
    if ( !iPlayer || !is_user_alive(iPlayer) )
    {
        client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_NO_VOTE_TARGETS")
        return PLUGIN_HANDLED
    }

    g_iVoteNo = 0
    g_iVoteYes = 0
    g_iVoteTargetUserid = iUserid
    get_user_name(iPlayer, g_szVoteTarget, charsmax(g_szVoteTarget))
    set_task(g_eSettings[SETTING_VOTE_DURATION], "taskVoteEnd", CAGE_VOTE_KEY)
    for ( new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer ++ )
    {
        if ( !is_user_connected(iPlayer) )
            continue

        cageSound(iPlayer, SOUND_MENU_NAV)
        cageMenu(iPlayer, MENU_VOTE_CONFIRM)
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuVoteConfirm(id, menu)
{
    new szItem[128]
    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_VOTE_YES")
    menu_additem(menu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAGE_VOTE_NO")
    menu_additem(menu, szItem)
}

public menuHandlerVoteConfirm(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    if ( item == 0 )    g_iVoteYes ++
    else                g_iVoteNo ++

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public taskVoteEnd()
{
    new iTotal = g_iVoteYes + g_iVoteNo
    new Float:fPercentage

    if ( iTotal )
        fPercentage = float(g_iVoteYes) / float(iTotal)

    new iTarget = find_player("k", g_iVoteTargetUserid)
    if ( iTotal && fPercentage >= g_eSettings[SETTING_VOTE_PERCENTAGE]
    && iTarget && is_user_alive(iTarget) )
    {
        new eCage[CAGE], bool:bFoundCage
        for ( new iItem = 0; iItem < g_iCage; iItem ++ )
        {
            ArrayGetArray(g_aCage, iItem, eCage)

            if ( eCage[CAGE_FLAGS] & FLAG_USED )
                continue

            cageCage(eCage, iTarget, true)
            ArraySetArray(g_aCage, iItem, eCage)
            bFoundCage = true
            break
        }

        if ( !bFoundCage )
            client_print_color(0, print_team_default, "%L %L", 0, "CAGE_CHAT_TAG", 0, "CAGE_CHAT_NO_CAGE")
        else
            client_print_color(0, print_team_default, "%L %L", 0, "CAGE_CHAT_TAG", 0, "CAGE_CHAT_VOTE_PASSED", g_szVoteTarget)
    }
    else
    {
        client_print_color(0, print_team_default, "%L %L", 0, "CAGE_CHAT_TAG", 0, "CAGE_CHAT_VOTE_FAILED", g_szVoteTarget)
    }

    g_fVoteNext = get_gametime() + g_eSettings[SETTING_VOTE_COOLDOWN]
}

public cageTask()
{
    new eCage[CAGE], iItem, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( g_ePlayerData[id][PDATA_NEXT_CAGE] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_CAGE] )
            {
                if ( (iItem = cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_ID])) != -1 )
                {
                    g_ePlayerData[id][PDATA_CAGE_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_CAGE] = 0.0

                    cageCage(eCage, id)
                    ArraySetArray(g_aCage, iItem, eCage)
                }
            }
            else if ( fCurrentTime - g_ePlayerData[id][PDATA_NEXT_CHECK] > 0.1 )
            {
                cageBar(id, 0)
                g_ePlayerData[id][PDATA_CAGE_ID] = 0
                g_ePlayerData[id][PDATA_NEXT_CAGE] = 0.0
            }
        }
    }
}

stock cageCreate(id, iItem)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eCage[CAGE]
    ArrayGetArray(g_aCageConfig, iItem, eCage)
    eCage[CAGE_ID] = iEnt
    eCage[CAGE_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_CAGE_GHOST] = eCage[CAGE_ID]
        g_ePlayerData[id][PDATA_OFFSET] = CAGE_OFFSET_BASE

        eCage[CAGE_FLAGS] |= FLAG_GHOST
    }

    cageSelect(eCage, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, CAGE_KEY)
    set_pev(iEnt, CAGE_ARRAY_ITEM, g_iCage)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aCage, eCage)
    if ( ++ g_iCage == 1 )
    {
        set_task(g_eSettings[SETTING_CAGE_TASK], "cageTask", CAGE_KEY, .flags = "b")
        EnableCage()
    }
}

stock cageCreateRelease(eCage[CAGE])
{
    new Float:fRight[3], Float:fForward[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eCage[CAGE_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(eCage[CAGE_ORIGIN], eCage[CAGE_ORIGIN_RELEASE])
    xs_vec_mul_scalar(fRight, -VIEW_FORWARD_OFFSET, fRight)
    xs_vec_mul_scalar(fForward, VIEW_RIGHT_OFFSET, fForward)
    xs_vec_add(eCage[CAGE_ORIGIN_RELEASE], fRight, eCage[CAGE_ORIGIN_RELEASE])
    xs_vec_add(eCage[CAGE_ORIGIN_RELEASE], fForward, eCage[CAGE_ORIGIN_RELEASE])
    eCage[CAGE_ORIGIN_RELEASE][2] += VIEW_UP_OFFSET

    engfunc(EngFunc_TraceLine, eCage[CAGE_ORIGIN], eCage[CAGE_ORIGIN_RELEASE], IGNORE_MONSTERS, eCage[CAGE_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, eCage[CAGE_ORIGIN_RELEASE])

    xs_vec_sub(eCage[CAGE_ORIGIN], eCage[CAGE_ORIGIN_RELEASE], fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, eCage[CAGE_ANGLES_RELEASE])
}

public cageRemove(iItem)
{
    new eCage[CAGE]
    ArrayDeleteItem(g_aCage, iItem)

    if ( -- g_iCage == 0 )
    {
        remove_task(CAGE_KEY)
        DisableCage()
    }

    for ( new i = iItem; i < g_iCage; i ++ )
    {
        ArrayGetArray(g_aCage, i, eCage)
        set_pev(eCage[CAGE_ID], CAGE_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eCage[CAGE],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Cage.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iCage; i ++ )
    {
        ArrayGetArray(g_aCage, i, eCage)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eCage[CAGE_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eCage[CAGE_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eCage[CAGE_ORIGIN][0], eCage[CAGE_ORIGIN][1], eCage[CAGE_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eCage[CAGE_ANGLES][0], eCage[CAGE_ANGLES][1], eCage[CAGE_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "CAGE_CHAT_TAG", id, "CAGE_CHAT_SAVE", szFile)
    fclose(iFile)

    cageSound(id, SOUND_MENU_NAV)
    cageMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Cage.ini", szFile)
    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataCage(iItem, iFlags, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataCage(iItem, iFlags, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataCage(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eCage[CAGE]
    cageCreate(0, iItem)
    ArrayGetArray(g_aCage, iCount, eCage)

    eCage[CAGE_FLAGS] = iFlags
    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eCage[CAGE_ORIGIN])
    xs_vec_copy(fAngles, eCage[CAGE_ANGLES])

    cageSetBox(eCage)
    cageSetSize(eCage)
    cageSetState(eCage)
    ArraySetArray(g_aCage, iCount, eCage)
}

public cageNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    cageSound(id, SOUND_MENU_NAV)
    cageMenu(id, MENU_ROOT)
}

public cageGodMode(id)
{
    new Float:flTakeDamage
    pev(id, pev_takedamage, flTakeDamage)
    set_pev(id, pev_takedamage, flTakeDamage == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    cageSound(id, SOUND_MENU_NAV)
    cageMenu(id, MENU_ROOT)
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isCage(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eCage[CAGE]
    if ( cageGet(eCage, iEnt) == -1 )
        return HAM_IGNORED

    new Float:fCurrentTime = get_gametime()
    if ( !(eCage[CAGE_FLAGS] & FLAG_ACTIVE)
    || (eCage[CAGE_FLAGS] & FLAG_USED)
    || !(eCage[CAGE_TEAM] & get_user_team(iActivator))
    || fCurrentTime < eCage[CAGE_NEXT_ACTIVE] )
        return HAM_IGNORED

    g_ePlayerData[iActivator][PDATA_NEXT_CHECK] = fCurrentTime
    if ( !g_ePlayerData[iActivator][PDATA_NEXT_CAGE] )
    {
        new iDuration
        iDuration = random_num(g_eSettings[SETTING_DEFAULT_HOLD_DURATION][0], g_eSettings[SETTING_DEFAULT_HOLD_DURATION][1])

        cageBar(iActivator, iDuration)
        g_ePlayerData[iActivator][PDATA_CAGE_ID] = iEnt
        g_ePlayerData[iActivator][PDATA_NEXT_CAGE] = fCurrentTime + iDuration
    }
    else if ( !fValue )
    {
        cageBar(iActivator, 0)
        g_ePlayerData[iActivator][PDATA_CAGE_ID] = 0
        g_ePlayerData[iActivator][PDATA_NEXT_CAGE] = 0.0
    }

    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isCage(iEnt) )
        return GetHamReturnStatus() == HAM_SUPERCEDE ? HAM_SUPERCEDE : HAM_IGNORED

    SetHamReturnInteger(FCAP_CONTINUOUS_USE | FCAP_ONOFF_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eCage[CAGE], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_CAGE_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += CAGE_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], CAGE_OFFSET_MIN, CAGE_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= CAGE_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], CAGE_OFFSET_MIN, CAGE_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            cageTrace(eCage, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_CAGE_ACTION] )
    {
        cageCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_CAGE_MENU] = 0
    if ( g_ePlayerData[id][PDATA_CAGE_GHOST] )
    {
        new eCage[CAGE], iItem
        if ( (iItem = cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_GHOST])) != -1 )
        {
            cageKill(eCage[CAGE_ID])
            cageRemove(iItem)
        }

        g_ePlayerData[id][PDATA_CAGE_GHOST] = 0
    }

    if ( g_ePlayerData[id][PDATA_CAGE_USED] )
    {
        new eCage[CAGE], iItem
        if ( (iItem = cageGet(eCage, g_ePlayerData[id][PDATA_CAGE_USED])) != -1 )
        {
            eCage[CAGE_FLAGS] &= ~FLAG_USED
            ArraySetArray(g_aCage, iItem, eCage)
        }

        g_ePlayerData[id][PDATA_CAGE_USED] = 0
    }
}

stock cageTrace(eCage[CAGE], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eCage[CAGE_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eCage[CAGE_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eCage[CAGE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eCage[CAGE_ORIGIN])

    cageSetBox(eCage)
    cageSetOffset(eCage)
    set_pev(eCage[CAGE_ID], pev_origin, eCage[CAGE_ORIGIN])
}

stock cageCheck(id)
{
    new eCage[CAGE], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist
    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = CAGE_CHECK
    for ( new i = 0; i < g_iCage; i ++ )
    {
        ArrayGetArray(g_aCage, i, eCage)
        xs_vec_sub(eCage[CAGE_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eCage[CAGE_ID], pev_absmin, fMins)
        pev(eCage[CAGE_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_CAGE_MENU] != iBest )
    {
        ArrayGetArray(g_aCage, g_ePlayerData[id][PDATA_CAGE_MENU], eCage)
        cageSelect(eCage, eCage[CAGE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_CAGE_MENU] = iBest
        cageMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock cageSetBox(eCage[CAGE])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eCage[CAGE_ANGLES][0] = -eCage[CAGE_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eCage[CAGE_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eCage[CAGE_MINS])
    xs_vec_copy(fMaxs, eCage[CAGE_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock cageSetOffset(eCage[CAGE])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eCage[CAGE_MINS][0]
    fGaps[1] = eCage[CAGE_MAXS][0]
    fGaps[2] = -eCage[CAGE_MINS][1]
    fGaps[3] = eCage[CAGE_MAXS][1]
    fGaps[4] = -eCage[CAGE_MINS][2]
    fGaps[5] = eCage[CAGE_MAXS][2]

    if ( eCage[CAGE_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eCage[CAGE_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eCage[CAGE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eCage[CAGE_ID], 0)
        get_tr2(0, TR_vecEndPos, eCage[CAGE_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eCage[CAGE_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eCage[CAGE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eCage[CAGE_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eCage[CAGE_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eCage[CAGE_ORIGIN], fVec1, eCage[CAGE_ORIGIN])
        }
    }
}

stock cageSetSize(eCage[CAGE])
{
    cageSelect(eCage, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eCage[CAGE_ID], eCage[CAGE_ORIGIN])
    set_pev(eCage[CAGE_ID], pev_angles, eCage[CAGE_ANGLES])
    set_pev(eCage[CAGE_ID], pev_solid, eCage[CAGE_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eCage[CAGE_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eCage[CAGE_ID], eCage[CAGE_MINS], eCage[CAGE_MAXS])
    engfunc(EngFunc_GetAttachment, eCage[CAGE_ID], 0, eCage[CAGE_ORIGIN_CAGE], NULL_VECTOR)
    cageCreateRelease(eCage)
}

stock cageSetState(eCage[CAGE])
{
    if ( eCage[CAGE_FLAGS] & FLAG_SHOW )
    {
        set_pev(eCage[CAGE_ID], pev_solid, SOLID_BBOX)
        cageSelect(eCage, TARGET_CLEAR)
    }
    else
    {
        set_pev(eCage[CAGE_ID], pev_solid, SOLID_NOT)
        cageSelect(eCage, TARGET_HIDE)
    }
}

stock cageStrip(id)
{
    new iWeapons[32], iNum, szName[32], iEnt
    get_user_weapons(id, iWeapons, iNum)
    for ( new i; i < iNum; i ++ )
    {
        if ( !get_weaponname(iWeapons[i], szName, charsmax(szName))
        || equal(szName, "weapon_knife") )
            continue

        iEnt = -1
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", szName)) > 0 )
        {
            if ( pev(iEnt, pev_owner) != id )
                continue

            ExecuteHam(Ham_RemovePlayerItem, id, iEnt)
            user_has_weapon(id, iWeapons[i], 0)
            ExecuteHamB(Ham_Item_Kill, iEnt)
            break
        }
    }

    engclient_cmd(id, "weapon_knife")
}

stock cageCage(eCage[CAGE], id, bool:bForced = false)
{
    cageStrip(id)
    eCage[CAGE_FLAGS] |= FLAG_USED
    g_ePlayerData[id][PDATA_CAGE_ID] = eCage[CAGE_ID]
    g_ePlayerData[id][PDATA_CAGE_USED] = eCage[CAGE_ID]
    cageSound(eCage[CAGE_ID], SOUND_CLOSE, false)
    engfunc(EngFunc_SetOrigin, id, eCage[CAGE_ORIGIN_CAGE])

    if ( g_eSettings[SETTING_WRITE_MESSAGE_ON_CAGE] )
        cageMessage(id, bForced)

    if ( g_eSettings[SETTING_PLAY_SOUND_ON_CAGE] )
        for ( new i = 1; i <= g_iMaxPlayers; i ++ )
            cageSound(i, SOUND_CAGE)
}

stock cageBar(id, iDuration)
{
    message_begin_f(MSG_ONE_UNRELIABLE, g_iBarTime, .player = id)
    write_short(iDuration)
    message_end()
}

stock cageSelect(eCage[CAGE], iAction)
{
    if ( iAction == TARGET_SELECT )
    {
        if ( eCage[CAGE_FLAGS] & FLAG_ACTIVE )  { set_pev(eCage[CAGE_ID], pev_rendercolor, Float:{0.0, 255.0, 0.0}); }
        else                                                { set_pev(eCage[CAGE_ID], pev_rendercolor, Float:{255.0, 0.0, 0.0}); }

        set_pev(eCage[CAGE_ID], pev_renderfx, kRenderFxGlowShell)
        set_pev(eCage[CAGE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eCage[CAGE_ID], pev_renderamt, 16.0)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_pev(eCage[CAGE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eCage[CAGE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eCage[CAGE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eCage[CAGE_ID], pev_renderamt, float(CAGE_GHOST_ALPHA))
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_pev(eCage[CAGE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eCage[CAGE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eCage[CAGE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eCage[CAGE_ID], pev_renderamt, 0.0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_pev(eCage[CAGE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eCage[CAGE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eCage[CAGE_ID], pev_rendermode, kRenderNormal)
        set_pev(eCage[CAGE_ID], pev_renderamt, 255.0)
    }
}

stock cageMessage(id, bool:bForced = false)
{
    new szName[MAX_NAME_LENGTH], szMessage[128], iHudObject
    get_user_name(id, szName, charsmax(szName))

    if ( bForced )
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])), szMessage, charsmax(szMessage))
    else
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE])), szMessage, charsmax(szMessage))

    switch ( g_iHudSlot )
    {
        case 0:  iHudObject = g_iHudObject_1
        case 1:  iHudObject = g_iHudObject_2
        default: iHudObject = g_iHudObject_3
    }

    set_hudmessage(g_eSettings[SETTING_HUD_COLOR][0], g_eSettings[SETTING_HUD_COLOR][1], g_eSettings[SETTING_HUD_COLOR][2], g_eSettings[SETTING_HUD_X], g_iHudCurrentY,
    g_eSettings[SETTING_HUD_EFFECT], g_eSettings[SETTING_HUD_FXTIME], g_eSettings[SETTING_HUD_HOLDTIME], g_eSettings[SETTING_HUD_FADEIN], g_eSettings[SETTING_HUD_FADEOUT])
    ShowSyncHudMsg(0, iHudObject, "%s%s", szName, szMessage)

    g_iHudSlot ++
    g_iHudCurrentY += HUD_Y_STEP
    if ( g_iHudCurrentY > HUD_Y_MAX )
    {
        g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
        g_iHudSlot = 0
    }
}

stock cageSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
        case SOUND_CAGE:        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_CAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_CAGE])), szSample, charsmax(szSample))
        case SOUND_OPEN:        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_OPEN], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_OPEN])), szSample, charsmax(szSample))
        case SOUND_CLOSE:       ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE])), szSample, charsmax(szSample))
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_VOICE, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock cageReset()
{
    new eCage[CAGE]
    for ( new i = 0; i < g_iCage; i ++ )
    {
        ArrayGetArray(g_aCage, i, eCage)
        eCage[CAGE_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aCage, i, eCage)
    }

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        g_ePlayerData[id][PDATA_NEXT_CAGE] = 0.0
        g_ePlayerData[id][PDATA_NEXT_CHECK] = 0.0
    }
}

stock cageGet(eCage[CAGE], iEnt)
{
    if ( !isCage(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, CAGE_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iCage )
        return -1

    ArrayGetArray(g_aCage, iItem, eCage)
    return iItem
}

stock bool:isCage(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == CAGE_KEY
}

stock cageKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            precache_model(szValue)
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_CAGE_ACTION] )
    {
        new eCage[CAGE]
        for ( new i = 0; i < g_iCage; i ++ )
        {
            ArrayGetArray(g_aCage, i, eCage)
            if ( eCage[CAGE_FLAGS] & FLAG_SHOW )
                continue

            cageSelect(eCage, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_CAGE_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_CAGE_ACTION] )
    {
        new eCage[CAGE]
        for ( new i = 0; i < g_iCage; i ++ )
        {
            ArrayGetArray(g_aCage, i, eCage)
            if ( eCage[CAGE_FLAGS] & FLAG_SHOW )
                continue

            cageSelect(eCage, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_CAGE_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableCage()
{
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
}

stock DisableCage()
{
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}





