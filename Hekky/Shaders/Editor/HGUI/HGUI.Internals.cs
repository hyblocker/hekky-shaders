namespace Hekky {
    public static partial class HGUI {
        /*
         * Tries to Auto-assign an ID based on the string's contents. Not bullet proof because of string collisions
         */
        private static bool AutoAssignId(string label) {
            if ( m_idStack.Count == 0 ) {
                m_idStack.Push(label.GetHashCode());
                return true;
            }

            return false;
        }
    }
}