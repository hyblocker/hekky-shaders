using System;

namespace Hekky
{
    public static class HekkyUtil
    {
        public static bool TestBitwiseFlag(object value, object flag) {
            return ((int) value & (int) flag) == (int) flag;
        }
    }

    public static class HekkyConstants
    {
        public static readonly string DiscordURL = "https://discord.gg/YWN7Z9T8DP";
        public static readonly string PatreonURL = "https://patreon.com/hyblocker";
        public static readonly string DocumentationURL = "https://docs.hyblocker.dev/shaders/pbr";
    }
}