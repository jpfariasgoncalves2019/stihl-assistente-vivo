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
      doc_chunks: {
        Row: {
          chunk_index: number
          content: string
          created_at: string | null
          doc_id: string
          embedding: string | null
          id: string
          page_number: number
          token_count: number | null
        }
        Insert: {
          chunk_index: number
          content: string
          created_at?: string | null
          doc_id: string
          embedding?: string | null
          id?: string
          page_number: number
          token_count?: number | null
        }
        Update: {
          chunk_index?: number
          content?: string
          created_at?: string | null
          doc_id?: string
          embedding?: string | null
          id?: string
          page_number?: number
          token_count?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "doc_chunks_doc_id_fkey"
            columns: ["doc_id"]
            isOneToOne: false
            referencedRelation: "doc_public_view"
            referencedColumns: ["doc_id"]
          },
          {
            foreignKeyName: "doc_chunks_doc_id_fkey"
            columns: ["doc_id"]
            isOneToOne: false
            referencedRelation: "docs"
            referencedColumns: ["id"]
          },
        ]
      }
      docs: {
        Row: {
          checksum: string
          created_at: string | null
          filename: string
          id: string
          model_code: string | null
          page_count: number | null
          source_path: string
        }
        Insert: {
          checksum: string
          created_at?: string | null
          filename: string
          id?: string
          model_code?: string | null
          page_count?: number | null
          source_path: string
        }
        Update: {
          checksum?: string
          created_at?: string | null
          filename?: string
          id?: string
          model_code?: string | null
          page_count?: number | null
          source_path?: string
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
      stg_calculadora: {
        Row: {
          descricao: string | null
          descricao_1: string | null
          observacao: string | null
          preco: string | null
          produtos: string | null
          referencia: string | null
        }
        Insert: {
          descricao?: string | null
          descricao_1?: string | null
          observacao?: string | null
          preco?: string | null
          produtos?: string | null
          referencia?: string | null
        }
        Update: {
          descricao?: string | null
          descricao_1?: string | null
          observacao?: string | null
          preco?: string | null
          produtos?: string | null
          referencia?: string | null
        }
        Relationships: []
      }
      stg_cod_alterados: {
        Row: {
          codigo_antigo: string | null
          codigo_novo: string | null
          col: string | null
          data_alteracao: string | null
          descricao: string | null
        }
        Insert: {
          codigo_antigo?: string | null
          codigo_novo?: string | null
          col?: string | null
          data_alteracao?: string | null
          descricao?: string | null
        }
        Update: {
          codigo_antigo?: string | null
          codigo_novo?: string | null
          col?: string | null
          data_alteracao?: string | null
          descricao?: string | null
        }
        Relationships: []
      }
      stg_conjunto_de_corte_ro_adeiras: {
        Row: {
          cilindrada_cm3: string | null
          codigo_material: string | null
          conjunto_de_corte: string | null
          descricao: string | null
          peso: string | null
          pot: string | null
          preco_real: number | null
        }
        Insert: {
          cilindrada_cm3?: string | null
          codigo_material?: string | null
          conjunto_de_corte?: string | null
          descricao?: string | null
          peso?: string | null
          pot?: string | null
          preco_real?: number | null
        }
        Update: {
          cilindrada_cm3?: string | null
          codigo_material?: string | null
          conjunto_de_corte?: string | null
          descricao?: string | null
          peso?: string | null
          pot?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
      stg_motossera: {
        Row: {
          codigo_material: string | null
          descricao: string | null
          modelos_compativeis: string | null
          preco_real: number | null
        }
        Insert: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Update: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
      stg_outras_maquinas: {
        Row: {
          codigo_material: string | null
          descricao: string | null
          modelos_compativeis: string | null
          preco_real: number | null
        }
        Insert: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Update: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
      stg_pecas: {
        Row: {
          codigo_material: string | null
          descricao: string | null
          modelos_compativeis: string | null
          preco_real: number | null
        }
        Insert: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Update: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
      stg_produtos_a_bateria: {
        Row: {
          codigo_material: string | null
          descricao: string | null
          modelos_compativeis: string | null
          preco_real: number | null
        }
        Insert: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Update: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
      stg_ro_adeiras_e_implementos: {
        Row: {
          codigo_material: string | null
          descricao: string | null
          modelos_compativeis: string | null
          preco_real: number | null
        }
        Insert: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Update: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_compativeis?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
      stg_sabres_correntes_pinhoes_limas: {
        Row: {
          codigo_material: string | null
          descricao: string | null
          modelos_maquinas: string | null
          preco_real: number | null
        }
        Insert: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_maquinas?: string | null
          preco_real?: number | null
        }
        Update: {
          codigo_material?: string | null
          descricao?: string | null
          modelos_maquinas?: string | null
          preco_real?: number | null
        }
        Relationships: []
      }
    }
    Views: {
      doc_public_view: {
        Row: {
          created_at: string | null
          doc_id: string | null
          model_code: string | null
          page_count: number | null
        }
        Insert: {
          created_at?: string | null
          doc_id?: string | null
          model_code?: string | null
          page_count?: number | null
        }
        Update: {
          created_at?: string | null
          doc_id?: string | null
          model_code?: string | null
          page_count?: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      apply_part_compat_staging: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
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
      match_doc_chunks: {
        Args: { match_count?: number; query_embedding: string }
        Returns: {
          chunk_index: number
          doc_id: string
          page_number: number
          similarity: number
        }[]
      }
      normalize_text: {
        Args: { t: string }
        Returns: string
      }
      parts_for_model: {
        Args: { limit_k?: number; mcode: string }
        Returns: {
          description: string
          part_code: string
          price: number
        }[]
      }
      pgp_armor_headers: {
        Args: { "": string }
        Returns: Record<string, unknown>[]
      }
      pgp_key_id: {
        Args: { "": string }
        Returns: string
      }
      resolve_model: {
        Args: { q: string }
        Returns: string
      }
      resolve_part: {
        Args: { q: string }
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
        Args:
          | { limit_k?: number; q: string }
          | { limit_n?: number; model_q?: string; part_q?: string }
        Returns: {
          description: string
          matched: boolean
          part_code: string
          price: number
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
      split_models: {
        Args: { s: string }
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
      tokenize: {
        Args: { t: string }
        Returns: string[]
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
