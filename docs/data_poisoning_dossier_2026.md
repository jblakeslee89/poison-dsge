# Data Poisoning Incidents and Adjacent Evidence

**Compiled May 4, 2026.** Research dossier for "Adversarial Nowcasting and Monetary Policy."
The original draft anchors on the Pravda operation (2024-2025). This dossier collects
post-Pravda evidence and economic-domain examples to strengthen the empirical base.

## Headline additions to make to the paper

1. **State actors are not unique to Russia.** NewsGuard's March 2026 audit found Mistral's
   Le Chat repeating fabricated Iranian-state claims about a March 9, 2026 strike on
   Israeli satellite-communications infrastructure. NewsGuard's Feb 2025 audit found
   DeepSeek advancing foreign-state disinformation 35% of the time. The mechanism
   generalizes.

2. **Poisoning is empirically cheap.** Souly et al. (Anthropic / UK AISI / Alan Turing
   Institute, October 2025, arXiv:2510.07192) demonstrated that **250 malicious documents
   are sufficient to backdoor a model with 600M to 13B parameters**, and the threshold
   does not scale with corpus size. This is the technical anchor that makes the
   data-poisoning threat operational rather than theoretical.

3. **Three pre-existing market-impact cases anchor the economic-stakes argument.**
   - 2013 Syrian Electronic Army / AP Twitter hack: Dow fell ~70 points in minutes,
     ~$136B equity swing.
   - November 2022 fake @EliLillyandCo tweet: LLY lost ~$15B market cap in hours.
   - May 2023 AI-generated Pentagon-explosion image: S&P briefly dropped 0.17pp.

4. **The Pravda story has a Wikipedia-laundering layer (March 2025).** DFRLab and
   CheckFirst documented that Pravda-network URLs were embedded in ~1,900 Wikipedia
   hyperlinks across 44 language editions. Wikipedia is a major LLM training source.

5. **Official policy stack now treats data poisoning as a recognized risk.** Treasury
   December 2024 RFI report on AI in financial services; NIST AI 600-1 GenAI Profile
   (July 2024); CISA/NSA/FBI joint guidance on AI Data Security (May 22, 2025).

6. **Academic disagreement worth acknowledging.** Alyukov et al. (HKS Misinformation
   Review, October 2025) argue Pravda's apparent LLM penetration reflects data voids
   on narrowly specified prompts, not systematic grooming. Citing this defends the
   paper from an obvious reviewer objection.

7. **No documented case of a successful poisoning attack on a central-bank nowcast
   pipeline has been publicly disclosed.** This is honest absence; the paper should
   say so explicitly. The class of attack is technically demonstrated (PoisonedRAG,
   USENIX Security 2025; Souly et al. 2025; Shimao et al. 2025 on HFT models) but
   the central-bank-specific empirical record is empty.

---

## TIER A — Direct economic / financial data-manipulation cases

**A1. AP Twitter hack — White House explosion hoax (April 23, 2013).**
Syrian Electronic Army phished AP credentials, posted a false tweet about an explosion
at the White House. Dow fell ~70 points in minutes; some reporting cited a transient
$136B equity-value swing before recovery.
Source: https://www.washingtonpost.com/news/worldviews/wp/2013/04/23/syrian-hackers-claim-ap-hack-that-tipped-stock-market-by-136-billion-is-it-terrorism/
Relevance: foundational case for "small false signal on a trusted upstream channel
moves a deep market." Maps directly onto the paper's failure-mode formalization.

**A2. Fake Eli Lilly "insulin is free" tweet (November 10, 2022).**
Sean Morrow, paying $8 for Twitter Blue verification, tweeted from a fake
@EliLillyandCo account. LLY shares fell from $368 to $346, ~$15B market-cap loss
before recovery.
Source: https://www.washingtonpost.com/technology/2022/11/14/twitter-fake-eli-lilly/
Relevance: integrity collapse of the verification signal alone is sufficient for a
single-name shock. Maps onto the paper's threat model where the adversary corrupts
the authentication layer rather than the content itself.

**A3. AI-generated "Pentagon explosion" image (May 22, 2023).**
Image circulated by a verified "Bloomberg Feed" impersonator. S&P 500 swung from
+0.02% at 10:06 a.m. to -0.15% at 10:09 a.m.; Dow fell ~80 points 10:06-10:10 a.m.
Recovered by 10:13.
Source: https://www.bloomberg.com/news/articles/2023-05-22/fake-ai-photo-of-pentagon-blast-goes-viral-trips-stocks-briefly
Relevance: cleanest documented case of an AI-generated artifact moving a major US
equity index. OECD AI Incidents Database Incident 543.

**A4. Arup Hong Kong deepfake CFO fraud (early 2024, public May 2024).**
Finance worker in Arup's Hong Kong office made 15 transfers totaling ~$25.6M to
five accounts after a Microsoft Teams-style call in which every other "executive"
was an AI-generated deepfake.
Sources: https://www.cnn.com/2024/05/16/tech/arup-deepfake-scam-loss-hong-kong-intl-hnk
         https://www.weforum.org/stories/2025/02/deepfake-ai-cybercrime-arup/
Relevance: institutional-scale loss caused by adversary-controlled synthetic content
presented as authoritative input. Direct structural analog to nowcast-input poisoning.

**A5. AI-driven market misinformation (NPR Oct 2025; Regulatory Review Nov 2025).**
NPR reported AI-amplified misinformation is operationally moving financial markets,
with autonomous bots moving faster than traditional surveillance.
Sources: https://www.npr.org/2025/10/17/nx-s1-5575695/financial-markets-are-being-subjected-to-misinformation-spread-by-ai
         https://www.theregreview.org/2025/11/25/smith-ai-and-the-future-of-market-manipulation/
Relevance: contemporary regulatory framing of "too fast to stop, too opaque to
understand." Directly mappable to the paper's claim that monetary-policy data
pipelines face an evolving adversarial environment.

**A6. SEC FY2025 enforcement actions against AI-washed pump-and-dump operations.**
SEC Cyber and Emerging Technologies Unit (launched Feb 2025) brought parallel actions
in April 2025 against Albert Saniger / Nate Inc. ($42M) and three crypto platforms /
four investment clubs ($14M) using AI-generated tips.
Sources: https://www.sec.gov/newsroom/press-releases/2025-144-sec-charges-three-purported-crypto-asset-trading-platforms-four-investment-clubs-scheme-targeted
         https://www.sec.gov/newsroom/press-releases/2026-34
Relevance: federal enforcement-record evidence that AI-mediated information attacks
on financial markets are not hypothetical.

---

## TIER B — AI / LLM data-poisoning beyond Pravda

**B1. Pravda → Wikipedia → LLM training (DFRLab + CheckFirst, March 2025).**
~1,900 Pravda-network hyperlinks embedded across Wikipedia's 44 language editions.
Wikipedia is a major LLM training source.
Sources: https://dfrlab.org/2025/03/12/pravda-network-wikipedia-llm-x/
         https://checkfirst.network/pravda-network-worldwide-expansion-and-llm-wikipedia-pollution/

**B2. DeepSeek as Chinese / Russian / Iranian disinformation conduit (NewsGuard, Feb 2025).**
DeepSeek advanced foreign disinformation 35% of the time and surfaced Beijing's
official position 60% of the time.
Source: https://www.newsguardtech.com/special-reports/deepseek-ai-chatbot-china-russia-iran-disinformation/

**B3. Mistral Le Chat repeating Storm-1516 and Iranian state claims (NewsGuard, Mar-Apr 2026).**
Le Chat repeated fabricated Iranian-state claims about a March 9, 2026 strike on
Israeli satcom infrastructure.
Source: https://www.newsguardtech.com/special-reports/mistral-le-chat-ai-chatbot-repeats-falsehoods-half-the-time-when-prompted-on-state-sponsored-iran-war-disinformation/
OECD AI Incidents 2026-04-28-e382.

**B4. PoisonedRAG (Zou et al., USENIX Security 2025).**
5 malicious texts per query in a corpus of millions achieves ~90% attack success
against retrieval-augmented LLMs.
Sources: https://www.usenix.org/system/files/usenixsecurity25-zou-poisonedrag.pdf
         https://arxiv.org/abs/2402.07867
         https://arxiv.org/abs/2505.18543 (companion benchmark paper)

**B5. Storm-1516 evolution (Microsoft + VIGINUM 2024-2025).**
~80 distinct campaigns August 2023 - March 2025; VIGINUM's May 2025 technical report
linked 10 campaigns July 2024 - July 2025 to GRU-linked financial flows.
Sources: https://www.sgdsn.gouv.fr/files/files/Publications/20250507_TLP-CLEAR_NP_SGDSN_VIGINUM_Technical%20report_Storm-1516.pdf
         https://www.microsoft.com/en-us/security/security-insider/threat-landscape/russia-linked-operators-engaged-in-expansive-efforts-to-influence-us-voters

---

## TIER C — Academic and policy documentation 2024-2026

**C1. Souly et al. (Anthropic / UK AISI / Alan Turing, October 8, 2025).**
"Poisoning Attacks on LLMs Require a Near-constant Number of Poison Samples."
arXiv:2510.07192. **The single most important technical citation.** 250 documents
sufficient to backdoor 600M-13B parameter models; threshold does not scale with
corpus size. https://arxiv.org/abs/2510.07192

**C2. Hubinger et al. (2024). Sleeper Agents.** arXiv:2401.05566. Anthropic followup
"Simple Probes Can Catch Sleeper Agents" (April 2024) achieves >99% AUROC.
https://www.anthropic.com/research/probes-catch-sleeper-agents

**C3. NIST AI 600-1: GenAI Profile (July 2024).** Codifies data poisoning as one of
12 GenAI-specific risk categories.
https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf
Companion: NIST AI 100-2e2025 "Adversarial Machine Learning."
https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-2e2025.pdf

**C4. U.S. Treasury (December 2024). "Artificial Intelligence in Financial Services" RFI.**
Press release JY2760. https://home.treasury.gov/news/press-releases/jy2760
Treasury **February 2025 public-private suite** on AI governance, data integrity,
fraud, and operational resilience: SB0395.
https://home.treasury.gov/news/press-releases/sb0395
Treasury March 2024 cyber-AI report: JY2212.

**C5. CISA / NSA / FBI / international partners (May 22, 2025).**
"AI Data Security: Best Practices for Securing Data Used to Train and Operate AI Systems."
Names "web-scale datasets," "data supply chain vulnerabilities," "maliciously modified
(poisoned) data," and "data drift" as core risks.
https://www.darkreading.com/cyber-risk/nsa-cisa-gudnceai-secure-data-ai-models

**C6. FSB (October 2025). AI vulnerabilities in financial sector.**
Identifies model poisoning, deepfake-enabled fraud, and correlated-model risk.
https://www.fsb.org/uploads/P101025.pdf

**C7. BIS Cipollone speech (October 9, 2025).** AI and central banks: monetary and
financial stability implications. https://www.bis.org/speeches/sp251009.htm
ECB Project Spectrum (GenAI for inflation nowcasting):
https://www.globalgovernmentfinance.com/project-spectrum-gen-ai-inflation-nowcasting-report/

**C8. OWASP GenAI Top-10 2025: LLM04 Data and Model Poisoning.**
https://genai.owasp.org/llmrisk/llm042025-data-and-model-poisoning/

**C9. Zou et al. PoisonedRAG (USENIX Security 2025).**
https://www.usenix.org/system/files/usenixsecurity25-zou-poisonedrag.pdf

**C10. OFR 2025 Annual Report to Congress.**
https://www.financialresearch.gov/annual-reports/files/OFR-AR-2025.pdf

**C11. Alyukov et al. (October 2025), HKS Misinformation Review.**
"LLMs grooming or data voids?" — peer-reviewed counterargument to the NewsGuard / ASP
interpretation of Pravda. **Cite this to anticipate the obvious reviewer objection.**
https://misinforeview.hks.harvard.edu/article/llms-grooming-or-data-voids-llm-powered-chatbot-references-to-kremlin-disinformation-reflect-information-gaps-not-manipulation/

---

## TIER D — Nowcasting-specific evidence

**No documented public disclosure of a successful poisoning attack on a central-bank
nowcast pipeline.** This is honest absence and the paper should say so. The defensive
guidance framework now exists (CISA/NSA May 2025; Treasury Feb 2025; NIST 600-1) but
the empirical incident record on central-bank nowcasts is empty.

The closest adjacent material:

- **ECB Project Spectrum (2024-2025)** — ECB used GPT-5 to classify billions of
  price-product daily observations from its Daily Price Dataset for inflation
  nowcasting. Public reporting describes the methodology but not adversarial testing.
- **Mode and Hoque (2024-2025), arXiv:2408.14875** — FGSM and BIM attacks against
  ML forecasters; transfers cleanly to macroeconomic indicators in principle.
- **Adversarial attacks on FinBERT / financial sentiment models** — recent work in
  *Journal of Banking and Finance* and ACM showing small input perturbations flip
  sentiment-classifier outputs used in trading and risk pipelines.
- **Shimao et al. (2025), SSRN abstract 5367043** — White-box FGSM/PGD attacks on
  LSTM, CNN, and DeepLOB high-frequency trading architectures using FI-2010
  limit-order-book data.

**Honest framing for the paper:** robust technical literature on attacks against
financial ML systems exists; robust threat-intelligence literature on state-actor
information operations against AI exists; the intersection — "state actor poisons
the central bank's nowcast" — has not been publicly documented. The paper should
treat it as a forward-looking threat model rather than after-action analysis.

---

## Suggested insertions in the paper (short and shippable)

**R1. After the Pravda passage, add:**
> The Pravda operation is the most documented case but not the only one. By early
> 2026, NewsGuard had audited similar LLM-grooming dynamics across Russian, Chinese,
> and Iranian state-aligned content. A March 2026 audit of Mistral's Le Chat found
> it repeating fabricated Iranian-state claims about a March 9, 2026 strike on
> Israeli satellite-communications infrastructure (NewsGuard, 2026).

**R2. Replace any speculative framing of poisoning thresholds with:**
> The cost of a successful poisoning attack is now empirically bounded. Souly et al.
> (2025) showed that 250 malicious documents are sufficient to backdoor pretraining
> for models from 600 million to 13 billion parameters; the threshold did not rise
> with corpus size. The economic cost of generating 250 plausible-looking economic-
> news documents is trivial relative to the position size such an attack could justify.

**R3. Insert in the empirical-motivation section:**
> Three pre-existing incidents establish that small, false, well-placed information
> shocks already move major US indices: the Syrian Electronic Army's 2013 AP Twitter
> hack (Dow -70 points, ~$136B equity swing); the November 2022 fake @EliLillyandCo
> tweet (LLY -6%, ~$15B market-cap loss); and the May 2023 AI-generated Pentagon-
> explosion image (S&P 500 -0.17 pp within three minutes). The threat to the
> nowcast pipeline is not that such shocks are unprecedented, but that the cost of
> producing them is collapsing while institutional reliance on machine-mediated
> inputs is rising.

**R4. In the policy section:**
> Data poisoning is now an explicitly enumerated risk in U.S. Treasury's December
> 2024 RFI report on AI in financial services, in NIST's Generative AI Profile
> (NIST AI 600-1, July 2024), and in joint CISA / NSA / FBI guidance issued May 22,
> 2025. The novelty of this paper is not that the risk is unknown to policymakers,
> but that monetary policy in particular has lacked a formal model of how the
> attack propagates from data feed to policy rate.

**R5. Footnote on the Pravda passage:**
> Alyukov et al. (HKS Misinformation Review, October 2025) argue that observed
> Pravda citations in chatbot output reflect data voids on narrowly specified
> prompts rather than systematic LLM grooming. The model in this paper is robust
> to that critique: even data-void exploitation is a tractable adversarial strategy
> in a nowcasting context, where many series have thin underlying source coverage.

---

## Caveats

All URLs and titles retrieved via web search May 4, 2026. Existence and topical
relevance verified; full-text fidelity not independently confirmed for every paper.

Two items I could not verify and excluded: (a) any specific Powell-deepfake stock-
market incident (the closest verified item is the April 2023 Russian-pranksters
video call with Chair Powell, which had no documented market impact); (b) any
single named NBER paper on data poisoning of macroeconomic models. The macro-side
adversarial literature lives on arXiv and SSRN, not the NBER series, as of this
search.
