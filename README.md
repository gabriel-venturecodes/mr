# NDL Platform - AI-Driven Market Research SaaS

The NDL platform is an AI-driven market research SaaS that ingests structured and unstructured text data (CSV, JSON, PDFs), organizes it into a knowledge graph, and applies a multi-agent system to generate grounded, testable hypotheses with full citations.

## 🚀 Demo Overview

This is a Tier-1 MVP demo showcasing:
- **Document ingestion** (CSV, JSON, PDF text)
- **AI-powered entity extraction** with canonicalization
- **Relation extraction** between entities
- **Hypothesis generation** with citations
- **Critic validation** to ensure grounded claims
- **Chat-like interface** for intuitive interaction

## 🏗️ Architecture

**Tech Stack:**
- **Backend:** Ruby on Rails 8.0 (monolith)
- **Database:** PostgreSQL with JSON support
- **AI/NLP:** OpenAI GPT-4o-mini via API
- **Background Jobs:** Sidekiq (ready for background processing)
- **Frontend:** Rails + Hotwire + Tailwind CSS
- **Vector Support:** pgvector (optional, fallback to text similarity)

**Core Services:**
- `AnalysisOrchestrator` - Main workflow controller
- `ChunkingService` - Token-aware text chunking
- `EntityExtractionService` - NER with canonicalization
- `RelationExtractionService` - Relation extraction between entities
- `SynthesisService` - Hypothesis generation with citations
- `CriticService` - Validation and fact-checking

## 🎯 Key Features

### Provenance-First Design
- Every entity, relation, and claim tracks source chunks
- Full citation trails for transparency
- Prompt versioning for reproducibility

### Type-Aware Entity Canonicalization
- Different similarity thresholds by entity type
- Manual alias tables for override
- Audit logging of all merges

### Bulletproof Validation
- JSON schema validation for all AI outputs
- Automatic repair attempts for malformed responses
- Fallback mechanisms for demo reliability

### Cost & Budget Controls
- Per-run token and cost caps
- Summary-first mode for budget overruns
- Comprehensive usage logging

## 🚀 Getting Started

### Prerequisites
- Ruby 3.3+
- PostgreSQL 14+
- **OpenAI API key** (required for AI features)

### Installation

1. **Clone and setup:**
   ```bash
   cd mr
   bundle install
   ```

2. **Environment setup:**
   ```bash
   cp .env.example .env
   ```
   
   **Important:** Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=sk-your-actual-openai-api-key-here
   ```
   
   🔑 **Get your API key:** https://platform.openai.com/api-keys

3. **Database setup:**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Start the server:**
   ```bash
   bin/rails server
   ```

5. **Open browser:**
   Navigate to `http://localhost:3000`

### 🔐 Security Notes
- **Never commit your `.env` file** - it contains sensitive API keys
- The `.env.example` file shows required environment variables
- Ensure your OpenAI API key has sufficient credits

## 📊 Demo Usage

### Golden Dataset
The demo comes pre-loaded with curated documents about:
- Customer survey data (Gen Z, Millennials preferences)
- Product reviews (EcoMilk oat milk)
- Market research reports (coffee consumption patterns)

### Try These Research Briefs:
- "How do young consumers perceive eco-friendly packaging?"
- "What are the main concerns about oat milk in coffee?"
- "Identify opportunities for sustainability messaging"

### Expected Results:
The system will generate 2-3 hypotheses with:
- ✅ **Citations** linking to source documents
- ✅ **Confidence scores** for evidence quality
- ✅ **Contradictory evidence** when found
- ✅ **Status indicators** (Verified/Rejected/Needs Evidence)

## 🔧 Architecture Details

### Database Schema
```
documents -> chunks -> embeddings (future)
entities <- relations -> entities  
hypotheses -> claims -> citation_chunk_ids
```

### AI Pipeline Flow
```
Upload → Chunk → Extract Entities → Extract Relations → 
Synthesize Hypotheses → Critic Validation → Present Results
```

### Provenance Tracking
Every AI-generated output includes:
- `prompt_version` - Template version used
- `model_id` - AI model identifier  
- `input_hash` - Content hash for caching
- `source_chunk_ids` - Evidence trail

## 🎨 UI Components

### Chat Interface
- File upload with drag-and-drop
- Research brief input with examples
- Real-time processing status
- Progress indicators

### Results Display
- Hypothesis cards with expandable details
- Citation preview on hover
- Evidence quality indicators
- Contradiction highlighting

### Document Management
- Upload status tracking
- Processing pipeline visibility
- Error handling and recovery

## 🔍 Demo Scenarios

### Scenario 1: Young Consumer Insights
**Brief:** "Find insights about how young consumers perceive eco-friendly products"

**Expected Hypothesis:**
"Gen Z consumers strongly prioritize eco-friendly packaging but show taste concerns when used in coffee preparations."

**Citations:** Customer survey chunks + product review data

### Scenario 2: Product Positioning
**Brief:** "Identify opportunities and concerns for EcoMilk positioning"

**Expected Insights:**
- Sustainability messaging resonates with target demographics
- Price sensitivity among younger consumers
- Coffee compatibility remains a challenge

## 🛡️ Reliability Features

### Demo-Day Safeguards
- Pre-computed golden dataset
- Fallback hypotheses for API failures
- Graceful degradation modes
- Comprehensive error handling

### Validation Pipeline
- Schema validation with auto-repair
- Citation requirement enforcement
- Similarity threshold checking
- Contradiction detection

### Monitoring & Logging
- Token usage tracking
- Cost monitoring
- Processing time metrics
- Error rate tracking

## 📈 Performance Targets

- **Cold start:** < 60 seconds
- **Warm queries:** < 10 seconds  
- **Citation coverage:** 100%
- **Hypothesis success rate:** >90%

## 🔮 Future Enhancements

### Technical
- [ ] Full pgvector integration
- [ ] Background job processing
- [ ] GraphQL API
- [ ] Real-time WebSocket updates

### AI Features
- [ ] Multi-modal document support
- [ ] Advanced contradiction detection
- [ ] Confidence calibration
- [ ] Human feedback loops

### Analytics
- [ ] Interactive visualizations
- [ ] Export to PowerPoint/PDF
- [ ] Collaborative annotations
- [ ] Version history

## 🚨 Known Limitations

- **Text-only ingestion** (no images/tables)
- **Simple similarity metrics** (pending pgvector)
- **Synchronous processing** (demo mode)
- **Fixed entity ontology** (6 types, 8 relations)

## 🤝 Contributing

This is a demo/prototype. For production deployment:

1. Add proper authentication (Devise)
2. Implement background jobs (Sidekiq)
3. Add comprehensive tests
4. Configure production secrets
5. Set up monitoring/alerts

## 📄 License

Demo/Educational purposes. Not for production use without proper security review.

---

**Built for NDL Platform Demo - August 2025**
# mr
