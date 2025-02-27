WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.s_suppkey) as supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        CASE 
            WHEN SUM(ps.ps_supplycost * ps.ps_availqty) IS NULL THEN 0
            ELSE SUM(ps.ps_supplycost * ps.ps_availqty) 
        END AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_brand
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
FilteredCTE AS (
    SELECT * FROM RecursiveCTE 
    WHERE supplier_count > 0 
          AND total_avail_qty > 100 
          AND (total_supply_cost / NULLIF(supplier_count, 0)) > 1000
),
FinalCTE AS (
    SELECT 
        f.*, 
        r.r_name AS region_name, 
        n.n_name AS nation_name,
        CASE 
            WHEN f.total_supply_cost IS NULL THEN 'Unknown'
            ELSE CONCAT('Total Supply Cost:', CAST(f.total_supply_cost AS VARCHAR(20)))
        END AS supply_cost_text
    FROM FilteredCTE f
    LEFT JOIN supplier s ON f.p_partkey = s.s_nationkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    f.*, 
    COALESCE(s.s_name, 'No Suppliers') AS supplier_name,
    ROW_NUMBER() OVER (ORDER BY f.total_supply_cost DESC) AS row_num,
    (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderstatus = 'F' AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31') AS avg_fulfilled_order_price
FROM FinalCTE f
FULL OUTER JOIN supplier s ON s.s_suppkey = f.p_partkey
WHERE f.rank_within_brand <= 5 OR (f.total_avail_qty = (SELECT MAX(total_avail_qty) FROM FilteredCTE) AND f.total_supply_cost IS NOT NULL)
ORDER BY f.total_avail_qty DESC, f.total_supply_cost ASC;
