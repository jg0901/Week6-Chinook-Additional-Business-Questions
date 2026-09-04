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

