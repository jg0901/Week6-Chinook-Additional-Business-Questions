# Week6: Chinook Additional Business Questions (Grow, Optimize, Protect)

# Catalogue Bundling Challenge

**The starting fact:** 1,519 of 3,503 tracks — 43% of the catalogue — have
never been purchased, while average order value sits at roughly $5.65.
Bundling a proven seller with unsold tracks from the same album is a way to
move dead stock and raise order value at the same time.

| | Question |
|---|---|
| **GROW** | Which top-selling tracks can we pair with unsold album tracks to create demand for dead catalogue? |
| **OPTIMIZE** | How should we size and price those bundles to increase order value? |
| **PROTECT** | At what discount does a bundle stop being worth doing? |

## Data constraint

Chinook does not include cost data, so true profit margins cannot be calculated. It also has no existing bundles or discounts to analyze. Therefore, PROTECT uses list price to find the break-even point—the discount at which a bundle would earn less revenue than selling its tracks separately. This protects revenue, not profit margin. If cost data were available, the same calculation could use contribution margin instead of list price.


## Price derivation

`dim_track` carries `media_type_name` but not list price, so price is
derived: video media types are $1.99, everything else $0.99 — the only two
price points in the dataset, confirmed in pre-cleaning analysis.

# GROW

**Business question:** Which top-selling tracks can we pair with unsold tracks from the same album to create demand for dead catalogue items?

**Fact:** InvoiceLine (`quantity`, and the *absence* of a row for a track)
**Dimensions:** Track, Album, Artist, Genre

**Query file:** [`sql/01_grow.sql`](../sql/01_grow.sql) (baseline in [`sql/00_baseline.sql`](../sql/00_baseline.sql))

---

## Query walkthrough

**1. Baseline (`vw_bundle_baseline`)**

This view calculates the current number of orders, tracks sold, total revenue, average order value (AOV), and average tracks per order. These metrics provide the benchmark for evaluating the bundle strategy. A successful bundle should increase AOV—not simply move unsold tracks.

**2. Candidate view (`vw_grow_bundle_candidates`)**

This view is built in three steps:

* `priced` assigns each track its list price based on `media_type_name`: $1.99 for video and $0.99 for all other media types—the only two price points in the dataset.

* `sold` calculates the total units sold for each `track_id` using `fact_invoiceline`.

* `track_status` left-joins `priced` with `sold`, ensuring that every track is included—even those with no sales. `COALESCE(units_sold, 0)` marks these tracks as unsold. The left join is essential because it allows the query to identify the absence of sales rather than only summarize existing purchases.

The results are then grouped by `artist_name` and `album_name`. Tracks are classified as either:

* **Anchor tracks:** tracks with at least one sale (`units_sold > 0`)
* **Unsold tracks:** tracks with no sales (`units_sold = 0`)

The `HAVING` clause requires each album to contain at least one track from both groups. To qualify as a bundle candidate, an album must have a proven track that can attract buyers and unsold tracks that could benefit from additional exposure.

**3. Shortlist and opportunity rollup**

The shortlist ranks candidates by `dead_tracks DESC`, prioritizing albums with the most unsold tracks. `album_units_sold DESC` is used as a tiebreaker to favor albums with stronger evidence of demand.

The rollup query summarizes the same candidate view to estimate the total size of the bundling opportunity.


---

## Results (from the run notebook)

**Baseline** — what any bundle has to beat:

| orders | tracks_sold | revenue | avg_order_value | avg_tracks_per_order |
|---|---|---|---|---|
| 412 | 2,240 | $2,328.60 | $5.65 | 5.44 |

**Top bundle candidates** (ordered by dead tracks, then album demand):

| Artist | Album | Genre | Lead anchor track | Tracks | Anchors | Dead | List value | Dead-stock value | Sell-through % |
|---|---|---|---|---|---|---|---|---|---|
| Lenny Kravitz | Greatest Hits | Rock | Mr. Cab Driver | 57 | 25 | 32 | $56.43 | $31.68 | 43.9 |
| Lost | Lost, Season 1 | TV Shows | Walkabout | 25 | 9 | 16 | $49.75 | $31.84 | 36.0 |
| The Office | The Office, Season 2 | TV Shows | The Dundies | 22 | 6 | 16 | $43.78 | $31.84 | 27.3 |
| Lost | Lost, Season 3 | TV Shows | The Glass Ballerina | 26 | 11 | 15 | $51.74 | $29.85 | 42.3 |
| Frank Sinatra | My Way: The Best Of Frank Sinatra [Disc 1] | Easy Listening | New York, New York | 24 | 10 | 14 | $23.76 | $13.86 | 41.7 |
| Heroes | Heroes, Season 1 | TV Shows | The Fix | 23 | 11 | 12 | $45.77 | $23.88 | 47.8 |
| Chico Buarque | Minha Historia | Latin | Samba De Orly | 34 | 23 | 11 | $33.66 | $10.89 | 67.6 |
| The Office | The Office, Season 3 | TV Shows | Gay Witch Hunt | 25 | 14 | 11 | $49.75 | $21.89 | 56.0 |
| Lost | Lost, Season 2 | TV Shows | Man of Science, Man of Faith (Premiere) | 24 | 13 | 11 | $47.76 | $21.89 | 54.2 |
| House Of Pain | House Of Pain | Hip Hop/Rap | Salutations | 19 | 8 | 11 | $18.81 | $10.89 | 42.1 |
| Marvin Gaye | Seek And Shall Find: More Of The Best (1963-1981) | R&B/Soul | Abraham, Martin And John | 18 | 8 | 10 | $17.82 | $9.90 | 44.4 |
| The Cult | Pure Cult: The Best Of The Cult [UK] | Rock | Sun King | 18 | 8 | 10 | $17.82 | $9.90 | 44.4 |
| Zeca Pagodinho | Ao Vivo [IMPORT] | Latin | Faixa Amarela | 19 | 9 | 10 | $18.81 | $9.90 | 47.4 |
| Iron Maiden | Live After Death | Metal | 2 Minutes To Midnight | 18 | 8 | 10 | $17.82 | $9.90 | 44.4 |
| Marisa Monte | Barulhinho Bom | Latin | Cérebro Eletrônico | 18 | 8 | 10 | $17.82 | $9.90 | 44.4 |
| Nirvana | From The Muddy Banks Of The Wishkah [Live] | Rock | Intro | 17 | 7 | 10 | $16.83 | $9.90 | 41.2 |
| Marcos Valle | Chill: Brazil (Disc 1) | Latin | Mas Que Nada | 17 | 7 | 10 | $16.83 | $9.90 | 41.2 |
| O Rappa | Radio Brasil (O Som da Jovem Vanguarda) | Electronica/Dance | Instinto Colectivo | 17 | 7 | 10 | $16.83 | $9.90 | 41.2 |
| Lost | LOST, Season 4 | TV Shows | Past, Present, and Future | 17 | 7 | 10 | $33.83 | $19.90 | 41.2 |
| Mötley Crüe | Motley Crue Greatest Hits | Metal | Kickstart My Heart | 17 | 7 | 10 | $16.83 | $9.90 | 41.2 |
| Chris Cornell | Carry On | Alternative | Safe and Sound | 14 | 4 | 10 | $13.86 | $9.90 | 28.6 |
| Gene Krupa | Up An' Atom | Jazz | Blue Rythm Fantasy | 22 | 13 | 9 | $21.78 | $8.91 | 59.1 |
| Chico Science & Nação Zumbi | Afrociberdelia | Latin | Samba Do Lado | 23 | 14 | 9 | $22.77 | $8.91 | 60.9 |
| U2 | Instant Karma: The Amnesty Int'l Campaign to Save Darfur | Pop | Give Peace a Chance | 23 | 14 | 9 | $22.77 | $8.91 | 60.9 |
| James Brown | Sex Machine | R&B/Soul | Hey America | 20 | 11 | 9 | $19.80 | $8.91 | 55.0 |

**Total reachable opportunity** (across all 256 qualifying albums, not just the top 25):

| candidate_albums | dead_tracks_reachable | dead_stock_value | avg_bundle_size | avg_sell_through_pct |
|---|---|---|---|---|
| 256 | 1,474 | $1,569.26 | 13.1 | 55.8 |

---

## Answer

Yes. The catalogue contains **256 albums** with both a proven seller and unsold tracks. Together, these albums account for **1,474 of the 1,519 unsold tracks (97%)**, representing **$1,569 in potential list-price revenue**. This shows that bundling is viable at scale—not just for a small number of albums.

However, the strongest candidates are not always the albums with the most unsold tracks:

* **Lenny Kravitz’s *Greatest Hits*** has the highest number of unsold tracks at **32**, but only **43.9%** of the album’s tracks have been purchased. Its large bundle potential comes with weaker evidence of demand.

* **Chico Buarque’s *Minha Historia*** has the highest sell-through rate among the top 25 candidates at **67.6%**, with 23 of its 34 tracks already purchased. Bundling its 11 unsold tracks with “Samba De Orly” is a safer option because the album has already demonstrated strong demand.

* **TV soundtrack albums** such as *Lost*, *The Office*, and *Heroes* appear repeatedly, each with **$20–$32 in unsold list value**. Because this pattern extends across multiple shows, soundtracks may be worth examining as a separate category.

The `lead_anchor_track`—the album’s highest-selling track—should be featured in the campaign because it provides the strongest reason for customers to click. However, when deciding which bundles to launch first, `sell_through_pct` is more useful than `dead_tracks` alone. An album with only 1 of 12 tracks purchased has many bundling opportunities but little evidence of demand. In contrast, an album with a **55%–67% sell-through rate** has already shown clear customer interest.

**Recommendation:** Launch the first bundle campaign using albums that have both a high number of unsold tracks and a sell-through rate above the **55.8% catalogue average**. Strong candidates include Chico Buarque, U2, Chico Science & Nação Zumbi, and James Brown. Lower-sell-through candidates such as Lenny Kravitz can be tested in a second wave after the strategy has been validated.


