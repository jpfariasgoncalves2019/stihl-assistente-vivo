import { useState, useRef, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { SendIcon, MessageCircleIcon, WrenchIcon, Search, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";

interface Message {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
}

interface PartResult {
  part_code: string;
  description: string;
  price: number;
  matched?: boolean;
}

const Index = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "welcome",
      text: "Olá! Sou o assistente STIHL para peças e equipamentos. Como posso ajudá-lo hoje? Você pode perguntar sobre preços, códigos ou compatibilidade de peças.",
      isUser: false,
      timestamp: new Date()
    }
  ]);
  const [inputValue, setInputValue] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [modelQuery, setModelQuery] = useState("");
  const [isSearching, setIsSearching] = useState(false);
  const [results, setResults] = useState<PartResult[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const { toast } = useToast();

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading) return;

    const userMessage: Message = {
      id: `user-${Date.now()}`,
      text: inputValue.trim(),
      isUser: true,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue("");
    setIsLoading(true);

    try {
      const { data, error } = await supabase.functions.invoke('chat', {
        body: {
          message: userMessage.text,
          channel: 'web',
          sender: 'web-user'
        }
      });

      if (error) throw error;

      const assistantMessage: Message = {
        id: `assistant-${Date.now()}`,
        text: data || "Desculpe, ocorreu um erro. Tente novamente.",
        isUser: false,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, assistantMessage]);
    } catch (error) {
      console.error('Erro ao enviar mensagem:', error);
      toast({
        title: "Erro de conexão",
        description: "Não foi possível enviar sua mensagem. Tente novamente.",
        variant: "destructive",
      });

      const errorMessage: Message = {
        id: `error-${Date.now()}`,
        text: "Desculpe, ocorreu um erro de conexão. Por favor, tente novamente ou entre em contato com nosso atendimento humano.",
        isUser: false,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const searchParts = async () => {
    if (!searchQuery && !modelQuery) {
      toast({
        title: "Digite algo para buscar",
        description: "Informe um modelo (ex: MS170) ou nome da peça (ex: carburador)",
        variant: "destructive",
      });
      return;
    }

    setIsSearching(true);
    try {
      const { data, error } = await supabase.rpc('search_parts', {
        q: searchQuery || modelQuery,
        limit_k: 10
      });

      if (error) throw error;

      setResults(data || []);
      
      if (!data || data.length === 0) {
        toast({
          title: "Nenhum resultado encontrado",
          description: "Tente buscar por: MS170, MS250, carburador, sabre, corrente",
        });
      } else {
        toast({
          title: `${data.length} peças encontradas`,
          description: "Resultados carregados com sucesso!",
        });
      }
    } catch (error) {
      console.error('Erro na busca:', error);
      toast({
        title: "Erro na busca",
        description: "Verifique sua conexão e tente novamente",
        variant: "destructive",
      });
    } finally {
      setIsSearching(false);
    }
  };

  const searchPartsForModel = async () => {
    if (!modelQuery) {
      toast({
        title: "Digite um modelo",
        description: "Ex: MS170, FS55, MS250",
        variant: "destructive",
      });
      return;
    }

    setIsSearching(true);
    try {
      const { data, error } = await supabase.rpc('parts_for_model', {
        mcode: modelQuery.toUpperCase(),
        limit_k: 10
      });

      if (error) throw error;

      const formattedResults = data?.map((item: any) => ({
        part_code: item.part_code,
        description: item.description,
        price: item.price,
        matched: true
      })) || [];

      setResults(formattedResults);
      
      if (!data || data.length === 0) {
        toast({
          title: "Nenhuma peça encontrada",
          description: `Modelo ${modelQuery} não possui peças cadastradas`,
        });
      } else {
        toast({
          title: `${data.length} peças compatíveis`,
          description: `Encontradas para o modelo ${modelQuery}`,
        });
      }
    } catch (error) {
      console.error('Erro na busca por modelo:', error);
      toast({
        title: "Erro na busca",
        description: "Verifique sua conexão e tente novamente",
        variant: "destructive",
      });
    } finally {
      setIsSearching(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-background to-stihl-gray-light/20">
      <div className="container mx-auto max-w-6xl p-4">
        {/* Header */}
        <div className="flex items-center gap-3 mb-6 py-4">
          <div className="flex items-center gap-2 bg-gradient-to-r from-primary to-primary-glow p-3 rounded-xl shadow-lg">
            <WrenchIcon className="h-6 w-6 text-primary-foreground" />
            <MessageCircleIcon className="h-6 w-6 text-primary-foreground" />
          </div>
          <div className="flex-1">
            <h1 className="text-3xl font-bold text-foreground">Assistente STIHL</h1>
            <p className="text-muted-foreground">Especialista em peças e equipamentos</p>
          </div>
          <div className="flex gap-2">
            <Badge variant="secondary">18 peças</Badge>
            <Badge variant="secondary">Sistema ativo</Badge>
          </div>
        </div>

        <Tabs defaultValue="chat" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="chat">Chat Inteligente</TabsTrigger>
            <TabsTrigger value="search">Busca Direta</TabsTrigger>
          </TabsList>
          
          <TabsContent value="chat" className="h-[calc(100vh-200px)]">
            <div className="flex flex-col h-full">

              {/* Chat Messages */}
              <Card className="flex-1 flex flex-col shadow-lg border-2 border-border/50">
                <div className="flex-1 overflow-y-auto p-4 space-y-4">
                  {messages.map((message) => (
                    <div
                      key={message.id}
                      className={`flex ${message.isUser ? 'justify-end' : 'justify-start'}`}
                    >
                      <div
                        className={`max-w-[80%] rounded-2xl px-4 py-3 ${
                          message.isUser
                            ? 'bg-gradient-to-r from-primary to-primary-glow text-primary-foreground shadow-stihl'
                            : 'bg-card border border-border text-card-foreground shadow-soft'
                        }`}
                      >
                        <p className="whitespace-pre-wrap leading-relaxed">{message.text}</p>
                        <div className={`text-xs mt-2 ${
                          message.isUser ? 'text-primary-foreground/70' : 'text-muted-foreground'
                        }`}>
                          {message.timestamp.toLocaleTimeString('pt-BR', {
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </div>
                      </div>
                    </div>
                  ))}
                  {isLoading && (
                    <div className="flex justify-start">
                      <div className="bg-card border border-border rounded-2xl px-4 py-3 shadow-soft">
                        <div className="flex items-center gap-2">
                          <div className="w-2 h-2 bg-primary rounded-full animate-bounce"></div>
                          <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                          <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                        </div>
                      </div>
                    </div>
                  )}
                  <div ref={messagesEndRef} />
                </div>

                {/* Input Area */}
                <div className="border-t border-border p-4">
                  <div className="flex gap-2">
                    <Input
                      value={inputValue}
                      onChange={(e) => setInputValue(e.target.value)}
                      onKeyPress={handleKeyPress}
                      placeholder="Digite sua pergunta sobre peças STIHL..."
                      disabled={isLoading}
                      className="flex-1 border-2 border-border focus:border-primary transition-colors"
                    />
                    <Button
                      onClick={handleSendMessage}
                      disabled={!inputValue.trim() || isLoading}
                      className="bg-gradient-to-r from-primary to-primary-glow hover:from-primary-glow hover:to-primary shadow-stihl"
                    >
                      <SendIcon className="h-4 w-4" />
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground mt-2 text-center">
                    Experimente: "Qual o preço do carburador da FS55?" ou "Peças compatíveis com MS170"
                  </p>
                </div>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="search" className="space-y-6">
            {/* Search Section */}
            <div className="grid md:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Search className="h-5 w-5" />
                    Busca Geral
                  </CardTitle>
                  <CardDescription>
                    Busque por nome da peça (carburador, sabre, corrente)
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <Input
                    placeholder="Ex: carburador, virabrequim, sabre..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && searchParts()}
                  />
                  <Button 
                    onClick={searchParts} 
                    disabled={isSearching}
                    className="w-full"
                  >
                    {isSearching && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                    Buscar Peças
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Search className="h-5 w-5" />
                    Busca por Modelo
                  </CardTitle>
                  <CardDescription>
                    Encontre peças compatíveis com um modelo específico
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <Input
                    placeholder="Ex: MS170, MS250, FS55..."
                    value={modelQuery}
                    onChange={(e) => setModelQuery(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && searchPartsForModel()}
                  />
                  <Button 
                    onClick={searchPartsForModel} 
                    disabled={isSearching}
                    className="w-full"
                    variant="outline"
                  >
                    {isSearching && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                    Peças Compatíveis
                  </Button>
                </CardContent>
              </Card>
            </div>

            {/* Results */}
            {results.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Resultados da Busca</CardTitle>
                  <CardDescription>
                    {results.length} peça(s) encontrada(s)
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid gap-4">
                    {results.map((part) => (
                      <div
                        key={part.part_code}
                        className="flex items-center justify-between p-4 border rounded-lg bg-card"
                      >
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <Badge variant="outline">{part.part_code}</Badge>
                            {part.matched && (
                              <Badge className="bg-green-100 text-green-800">Match</Badge>
                            )}
                          </div>
                          <p className="font-medium mt-1">{part.description}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold text-primary">
                            R$ {part.price?.toFixed(2)}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Examples */}
            <Card>
              <CardHeader>
                <CardTitle>Exemplos de Busca</CardTitle>
                <CardDescription>
                  Experimente estas pesquisas para testar o sistema
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid md:grid-cols-3 gap-4">
                  <div className="p-4 bg-muted rounded-lg">
                    <h4 className="font-semibold text-foreground mb-2">Por Modelo:</h4>
                    <p className="text-sm text-muted-foreground">MS170, MS162, FS55, FS38</p>
                  </div>
                  <div className="p-4 bg-muted rounded-lg">
                    <h4 className="font-semibold text-foreground mb-2">Por Peça:</h4>
                    <p className="text-sm text-muted-foreground">carburador, sabre, corrente</p>
                  </div>
                  <div className="p-4 bg-muted rounded-lg">
                    <h4 className="font-semibold text-foreground mb-2">Por Código:</h4>
                    <p className="text-sm text-muted-foreground">1108-120-0600, 3005-000-4813</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default Index;