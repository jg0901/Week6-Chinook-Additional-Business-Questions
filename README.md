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


---

# OPTIMIZE

**Business question:** How should bundles be sized and priced to increase average order value (AOV)?

**Fact:** InvoiceLine (`line_amount`, `quantity`)
**Dimensions:** Track, Album

---

## Query walkthrough

**1. Pricing view (`vw_optimize_bundle_pricing`)**

This view cross-joins each of the 256 candidate albums from GROW with the single-row baseline containing the current AOV of $5.65. It then calculates each bundle’s price at three discount levels: 10%, 20%, and 30% off its total list value.

A `CASE` statement assigns a `pricing_headroom` label based on the deepest discount the bundle can offer while keeping its price at or above the current AOV.

The calculation uses the live baseline view instead of hardcoding $5.65. This allows the recommended pricing tier to update automatically when the underlying sales data changes.

**2. Headroom summary**

This query groups all 256 candidates by `pricing_headroom`. It shows how many bundles—and how many unsold tracks—can support each discount level while still meeting or exceeding the current AOV.

**3. Minimum bundle size by discount tier**

This separate calculation determines the minimum number of $0.99 tracks needed for a bundle to remain above the current AOV at each discount level.

This acts as a simple pricing guardrail: choose a discount tier, then use the result to determine the minimum number of tracks the bundle should contain.

---

## Results

**Pricing headroom across all 256 GROW candidates:**

| Pricing headroom | Bundles | Avg bundle size | Avg list value | Dead tracks covered |
|---|---|---|---|---|
| Safe to 30% off | 223 | 14.2 | $15.01 | 1,389 |
| Too small to discount | 13 | 3.5 | $3.50 | 24 |
| Safe to 20% off | 12 | 8.0 | $7.92 | 34 |
| Safe to 10% off | 8 | 7.0 | $6.93 | 27 |

**Minimum bundle size to clear the $5.65 AOV, by discount tier:**

| Discount | Min. tracks to clear AOV |
|---|---|
| 10% off | 7 |
| 20% off | 8 |
| 30% off | 9 |
| 40% off | 10 |

---

## Answer

**Bundle size creates room for discounts.** Of the 256 candidate bundles, 223 (87%) can be discounted by 30% and still remain above the current $5.65 average order value.

These bundles contain an average of 14.2 tracks, with an average list value of $15.01. Even after a 30% discount, the average bundle price would be about $10.51—well above the current AOV. Together, they cover 1,389 of the 1,474 reachable unsold tracks (94%), meaning nearly the entire GROW opportunity has enough pricing flexibility.

At the other end, 13 bundles contain an average of only 3.5 tracks, with a list value of about $3.50. Their full price is already below the current AOV, so discounting cannot solve the problem. These are sizing problems, not pricing problems.

These smaller bundles should be:

* Offered at full price as add-ons
* Combined with another album by the same artist
* Excluded from the bundle campaign

**Recommendation—a simple sizing and pricing rule:**

* **9 or more tracks:** up to 30% off
* **8 tracks:** up to 20% off
* **7 tracks:** up to 10% off
* **6 tracks:** full price
* **5 or fewer tracks:** expand the bundle or exclude it

This rule ensures that each bundle remains at or above the current $5.65 AOV.


In practice: default new bundles to **20–30% off** since almost all GROW
candidates clear that bar comfortably, and only fall back to a smaller
discount (or none) for the minority of albums under ~8 tracks.

---

# PROTECT

**Business question:** How much can we discount a bundle before it earns less than selling its tracks individually—and how can we avoid discounting tracks that customers would have purchased at full price?

**Fact:** InvoiceLine (`line_amount`)
**Dimensions:** Track, Album

## Query walkthrough

**1. Break-even view (`vw_protect_bundle_breakeven`)**

This view divides each candidate bundle’s `bundle_list_value` into two parts:

* `revenue_at_risk`: the value of the anchor tracks. Because these tracks have sold before, discounting them could reduce revenue from purchases that might have occurred at full price.
* `incremental_upside`: the value of the unsold tracks. Since these tracks have no previous sales, their value represents the bundle’s potential additional revenue.

The break-even discount is the point at which the discounted bundle price equals the full list value of its anchor tracks:

```text
max_safe_discount = 1 - (anchor_value / bundle_list_value)
```

Discounting beyond this point would make the bundle earn less than the anchor tracks could have earned separately, even if it helps move unsold tracks.

A `CASE` statement then classifies each bundle’s discount headroom as **Wide**, **Moderate**, or **Discount cautiously**.

**2. Safest-bundles query**

This query ranks candidates by `max_safe_discount_pct DESC`. Bundles rank higher when anchor tracks make up a smaller share of their total value, meaning more of the discount is supported by tracks with no previous sales.

**3. Portfolio rollup**

This query totals `incremental_upside` and `revenue_at_risk` across all 256 candidate bundles and groups them by `discount_risk`. This shows how much potential bundle value comes from unsold tracks and how much comes from previously purchased tracks that could be cannibalized.

**4. Combined recommendation**

The final query joins the PROTECT results with the OPTIMIZE pricing view. It keeps only bundles that:

* Can support a 20–30% discount while remaining above the current AOV
* Have at least 20% break-even headroom before risking anchor-track revenue

The result is an actionable shortlist of bundles that satisfy both the AOV and revenue-protection requirements.

**Safest bundles** (highest break-even discount, most dead-stock-heavy):

| Artist | Album | Size | Anchors | Dead | List value | Revenue at risk | Incremental upside | % Incremental | Max safe discount | Risk |
|---|---|---|---|---|---|---|---|---|---|---|
| Deep Purple | The Final Concerts (Disc 2) | 4 | 1 | 3 | $3.96 | $0.99 | $2.97 | 75.0 | 75.0% | Wide headroom |
| The Office | The Office, Season 2 | 22 | 6 | 16 | $43.78 | $11.94 | $31.84 | 72.7 | 72.7% | Wide headroom |
| Chris Cornell | Carry On | 14 | 4 | 10 | $13.86 | $3.96 | $9.90 | 71.4 | 71.4% | Wide headroom |
| Black Sabbath | Black Sabbath | 7 | 2 | 5 | $6.93 | $1.98 | $4.95 | 71.4 | 71.4% | Wide headroom |
| Audioslave | Revelations | 14 | 5 | 9 | $14.86 | $4.95 | $9.91 | 66.7 | 66.7% | Wide headroom |
| Led Zeppelin | Physical Graffiti [Disc 1] | 6 | 2 | 4 | $5.94 | $1.98 | $3.96 | 66.7 | 66.7% | Wide headroom |
| The Office | The Office, Season 1 | 6 | 2 | 4 | $11.94 | $3.98 | $7.96 | 66.7 | 66.7% | Wide headroom |
| Gilberto Gil | Quanta Gente Veio ver–Bônus De Carnaval | 3 | 1 | 2 | $2.97 | $0.99 | $1.98 | 66.7 | 66.7% | Wide headroom |
| Lulu Santos | Lulu Santos – RCA 100 Anos De Música... | 14 | 5 | 9 | $13.86 | $4.95 | $8.91 | 64.3 | 64.3% | Wide headroom |
| Gilberto Gil | As Canções de Eu Tu Eles | 14 | 5 | 9 | $13.86 | $4.95 | $8.91 | 64.3 | 64.3% | Wide headroom |
| Lost | Lost, Season 1 | 25 | 9 | 16 | $49.75 | $17.91 | $31.84 | 64.0 | 64.0% | Wide headroom |
| U2 | All That You Can't Leave Behind | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| The Doors | The Doors | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| Iron Maiden | A Real Live One | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| Pearl Jam | Ten | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| Jamiroquai | The Return Of The Space Cowboy | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| Foo Fighters | One By One | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| Skank | O Samba Poconé | 11 | 4 | 7 | $10.89 | $3.96 | $6.93 | 63.6 | 63.6% | Wide headroom |
| Apocalyptica | Plays Metallica By Four Cellos | 8 | 3 | 5 | $7.92 | $2.97 | $4.95 | 62.5 | 62.5% | Wide headroom |
| Santana | Santana – As Years Go By | 8 | 3 | 5 | $7.92 | $2.97 | $4.95 | 62.5 | 62.5% | Wide headroom |
| Pearl Jam | Pearl Jam | 13 | 5 | 8 | $12.87 | $4.95 | $7.92 | 61.5 | 61.5% | Wide headroom |
| Black Label Society | Alcohol Fueled Brewtality Live! [Disc 1] | 13 | 5 | 8 | $12.87 | $4.95 | $7.92 | 61.5 | 61.5% | Wide headroom |
| Vinícius De Moraes | Vinicius De Moraes | 15 | 6 | 9 | $14.85 | $5.94 | $8.91 | 60.0 | 60.0% | Wide headroom |
| Motörhead | Ace Of Spades | 15 | 6 | 9 | $14.85 | $5.94 | $8.91 | 60.0 | 60.0% | Wide headroom |
| Foo Fighters | In Your Honor [Disc 1] | 10 | 4 | 6 | $9.90 | $3.96 | $5.94 | 60.0 | 60.0% | Wide headroom |

**Portfolio view — how much of the programme is incremental vs. at risk:**

| Discount risk | Bundles | Dead tracks | Incremental upside | Revenue at risk | Avg. safe discount |
|---|---|---|---|---|---|
| Wide headroom | 174 | 1,192 | $1,284.08 | $1,130.43 | 53.1% |
| Moderate headroom | 59 | 237 | $240.63 | $570.42 | 29.7% |
| Discount cautiously | 23 | 45 | $44.55 | $272.25 | 13.8% |

The totals reconcile exactly with GROW: 174 + 59 + 23 = 256 bundles, while 1,192 + 237 + 45 = 1,474 unsold tracks. This is expected because PROTECT groups the same candidate set differently rather than applying an additional filter.

## Answer

**Most bundles have substantial discount headroom.** Of the 256 candidates, 174 (68%) fall under **Wide headroom**, meaning they can absorb a discount of at least 40% before their price drops below the value of their anchor tracks.

Across the portfolio’s $3,542 total list value:

* **$1,569** comes from previously unsold tracks and represents potential incremental upside.
* **$1,973** comes from anchor tracks and could be at risk if bundles are discounted too heavily.

However, **wide percentage headroom does not always make a bundle worth launching**. Deep Purple’s *The Final Concerts (Disc 2)*, for example, can theoretically support a 75% discount, but its full list value is only $3.96. Because that is already below the current $5.65 AOV, even a full-price offer would not raise AOV.

In contrast, *The Office, Season 2* combines both:

* **72.7% break-even headroom**
* **16 unsold tracks**
* **$43.78 in total list value**

This is the type of bundle worth prioritising: large enough to raise AOV and flexible enough to discount safely.

* The discounted price remains above the current AOV.
* The discount stays within the bundle’s break-even limit.

The intersection of GROW, OPTIMIZE, and PROTECT—not any single metric—is the true launch list.

**Recommendation:**

1. Use the combined **GROW ∩ OPTIMIZE ∩ PROTECT** results as the launch list. Each bundle should have evidence of demand, enough value to raise AOV, and sufficient protection.

2. Start qualifying bundles at **20% off**. This provides a meaningful customer incentive while staying within both the AOV and break-even limits of the combined shortlist.

3. Keep the 23 **Discount cautiously** bundles at full or near-full price. Their average safe discount is only 13.8%, so deeper discounts could reduce revenue from tracks that might otherwise sell at full price.

4. Monitor large TV and soundtrack bundles such as *The Office* and *Lost*. Although they have wide percentage headroom, they also contain the highest absolute `revenue_at_risk` values—between $11.94 and $17.91—so exceeding their discount limits could be costly.

