export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.4"
  }
  public: {
    Tables: {
      assistant_prompts: {
        Row: {
          created_at: string | null
          examples: Json | null
          id: string
          instructions: string
          name: string
          persona: string
        }
        Insert: {
          created_at?: string | null
          examples?: Json | null
          id?: string
          instructions: string
          name: string
          persona: string
        }
        Update: {
          created_at?: string | null
          examples?: Json | null
          id?: string
          instructions?: string
          name?: string
          persona?: string
        }
        Relationships: []
      }
      attendant_prompts: {
        Row: {
          content: string
          created_at: string | null
          id: number
          is_active: boolean | null
          role: string | null
          updated_at: string | null
          version: string | null
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: number
          is_active?: boolean | null
          role?: string | null
          updated_at?: string | null
          version?: string | null
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: number
          is_active?: boolean | null
          role?: string | null
          updated_at?: string | null
          version?: string | null
        }
        Relationships: []
      }
      conversation_logs: {
        Row: {
          answer_preview: string | null
          channel: string
          created_at: string | null
          id: number
          resolved_model_code: string | null
          resolved_part_code: string | null
          user_message: string
        }
        Insert: {
          answer_preview?: string | null
          channel: string
          created_at?: string | null
          id?: number
          resolved_model_code?: string | null
          resolved_part_code?: string | null
          user_message: string
        }
        Update: {
          answer_preview?: string | null
          channel?: string
          created_at?: string | null
          id?: number
          resolved_model_code?: string | null
          resolved_part_code?: string | null
          user_message?: string
        }
        Relationships: []
      }
      equipment_models: {
        Row: {
          created_at: string | null
          display_name: string | null
          family: string
          id: string
          model_code: string
          specs: Json | null
        }
        Insert: {
          created_at?: string | null
          display_name?: string | null
          family: string
          id?: string
          model_code: string
          specs?: Json | null
        }
        Update: {
          created_at?: string | null
          display_name?: string | null
          family?: string
          id?: string
          model_code?: string
          specs?: Json | null
        }
        Relationships: []
      }
      model_aliases: {
        Row: {
          alias: string
          id: string
          model_code: string
        }
        Insert: {
          alias: string
          id?: string
          model_code: string
        }
        Update: {
          alias?: string
          id?: string
          model_code?: string
        }
        Relationships: []
      }
      part_aliases: {
        Row: {
          alias: string
          id: string
          part_code: string
        }
        Insert: {
          alias: string
          id?: string
          part_code: string
        }
        Update: {
          alias?: string
          id?: string
          part_code?: string
        }
        Relationships: []
      }
      part_model_compat: {
        Row: {
          model_code: string
          part_id: string
        }
        Insert: {
          model_code: string
          part_id: string
        }
        Update: {
          model_code?: string
          part_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "part_model_compat_part_id_fkey"
            columns: ["part_id"]
            isOneToOne: false
            referencedRelation: "parts"
            referencedColumns: ["id"]
          },
        ]
      }
      part_prices: {
        Row: {
          currency: string
          id: string
          part_id: string
          price: number
          source: string | null
          valid_from: string | null
        }
        Insert: {
          currency?: string
          id?: string
          part_id: string
          price: number
          source?: string | null
          valid_from?: string | null
        }
        Update: {
          currency?: string
          id?: string
          part_id?: string
          price?: number
          source?: string | null
          valid_from?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "part_prices_part_id_fkey"
            columns: ["part_id"]
            isOneToOne: false
            referencedRelation: "parts"
            referencedColumns: ["id"]
          },
        ]
      }
      parts: {
        Row: {
          created_at: string | null
          description: string
          id: string
          part_code: string
        }
        Insert: {
          created_at?: string | null
          description: string
          id?: string
          part_code: string
        }
        Update: {
          created_at?: string | null
          description?: string
          id?: string
          part_code?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      armor: {
        Args: { "": string }
        Returns: string
      }
      dearmor: {
        Args: { "": string }
        Returns: string
      }
      gen_random_bytes: {
        Args: { "": number }
        Returns: string
      }
      gen_random_uuid: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      gen_salt: {
        Args: { "": string }
        Returns: string
      }
      gtrgm_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_options: {
        Args: { "": unknown }
        Returns: undefined
      }
      gtrgm_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      pgp_armor_headers: {
        Args: { "": string }
        Returns: Record<string, unknown>[]
      }
      pgp_key_id: {
        Args: { "": string }
        Returns: string
      }
      search_docs_secure: {
        Args: { model_q?: string; part_q?: string; top_k?: number }
        Returns: {
          heading: string
          item_number: number
          model_code: string
          page: number
          part_code: string
          part_desc: string
        }[]
      }
      search_parts: {
        Args: { limit_n?: number; model_q?: string; part_q?: string }
        Returns: {
          description: string
          model: string
          part_code: string
          price_brl: number
          rank: number
        }[]
      }
      set_limit: {
        Args: { "": number }
        Returns: number
      }
      show_limit: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      show_trgm: {
        Args: { "": string }
        Returns: string[]
      }
      suggest_models: {
        Args: { limit_n?: number; q: string }
        Returns: {
          category: string
          model_code_std: string
          similarity_score: number
        }[]
      }
      unaccent: {
        Args: { "": string }
        Returns: string
      }
      unaccent_init: {
        Args: { "": unknown }
        Returns: unknown
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
