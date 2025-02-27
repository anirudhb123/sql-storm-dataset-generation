WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
AvailableParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10 AND p.p_retailprice BETWEEN 100.00 AND 500.00
    GROUP BY ps.ps_partkey
),
HighPriceOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_totalprice
),
CrossRegionNations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name NOT IN ('ASIA', 'EUROPE')
)
SELECT DISTINCT
    p.p_name,
    p.p_brand,
    COALESCE(rnk.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN hpo.o_orderkey IS NOT NULL THEN hpo.line_item_count
        ELSE 0
    END AS orders_with_high_price,
    COALESCE(ap.total_availqty, 0) AS total_avail_qty
FROM part p
LEFT JOIN RankedSuppliers rnk ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rnk.s_suppkey ORDER BY ps.ps_availqty DESC LIMIT 1)
LEFT JOIN HighPriceOrders hpo ON hpo.line_item_count > (SELECT AVG(line_item_count) FROM HighPriceOrders)
LEFT JOIN AvailableParts ap ON p.p_partkey = ap.ps_partkey
WHERE p.p_retailprice IS NOT NULL
ORDER BY p.p_name ASC NULLS LAST;
