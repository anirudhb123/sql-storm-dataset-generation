
WITH FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal,
           n.n_name AS nation_name,
           CONCAT('Supplier ', s.s_name, ' (', s.s_address, ') - Balance: $', CAST(ROUND(s.s_acctbal, 2) AS VARCHAR(20))) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000 AND n.n_name IN ('USA', 'Canada')
),
PartSuppSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           MIN(ps.ps_supplycost) AS min_supply_cost,
           MAX(ps.ps_supplycost) AS max_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, COUNT(*) AS total_line_items, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           LISTAGG(DISTINCT l.l_shipmode, ', ') WITHIN GROUP (ORDER BY l.l_shipmode ASC) AS unique_ship_modes
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT f.s_name, f.nation_name, f.supplier_info, p.p_name,
       ps.total_avail_qty, ps.min_supply_cost, ps.max_supply_cost,
       l.total_line_items, l.total_revenue, l.unique_ship_modes
FROM FilteredSuppliers f
JOIN PartSuppSummary ps ON f.s_suppkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN LineItemAnalysis l ON f.s_suppkey = l.l_orderkey
WHERE l.total_revenue > 10000
ORDER BY f.s_acctbal DESC, l.total_revenue DESC;
