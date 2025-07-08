
WITH RECURSIVE Supplier_CTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
Part_Supply AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, 
           ps.ps_supplycost, p.p_retailprice,
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
Order_Stats AS (
    SELECT o.o_orderkey, o.o_totalprice,
           AVG(l.l_discount) OVER (PARTITION BY o.o_orderkey) AS avg_discount,
           SUM(l.l_extendedprice) OVER (PARTITION BY o.o_orderkey) AS total_lineitem_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
),
Discount_Evaluation AS (
    SELECT os.o_orderkey, os.o_totalprice, os.avg_discount, 
           CASE WHEN os.avg_discount > 0.1 THEN 'High Discount' 
                WHEN os.avg_discount IS NULL THEN 'Unknown Discount'
                ELSE 'Regular Discount' END AS discount_category
    FROM Order_Stats os
    WHERE os.total_lineitem_price IS NOT NULL
)
SELECT 
    r.r_name AS region_name, 
    supp.s_name AS supplier_name, 
    part.p_name AS part_name, 
    ds.discount_category,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    LISTAGG(DISTINCT CONCAT(part.p_name, ' (', ps.ps_availqty, ')'), '; ') WITHIN GROUP (ORDER BY part.p_name) AS part_details,
    CASE WHEN COUNT(DISTINCT ds.discount_category) > 1 THEN 'Varied Discounts' ELSE MIN(ds.discount_category) END AS discount_variation
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier supp ON n.n_nationkey = supp.s_nationkey
LEFT JOIN Part_Supply part ON supp.s_suppkey = part.p_partkey
LEFT JOIN Discount_Evaluation ds ON ds.o_orderkey = part.p_partkey
LEFT JOIN partsupp ps ON part.p_partkey = ps.ps_partkey
WHERE ds.discount_category IS NOT NULL
OR ds.discount_category IS NULL
GROUP BY r.r_name, supp.s_name, part.p_name, ds.discount_category
HAVING SUM(ps.ps_availqty) > 5
ORDER BY r.r_name, supp.s_name;
