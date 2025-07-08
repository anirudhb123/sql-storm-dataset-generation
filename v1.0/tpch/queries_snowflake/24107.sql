WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
),

AggregatedPrices AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_orderkey
),

TopOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus != 'F'
)

SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    COALESCE(n.n_name, 'No Nation') AS supplier_nation,
    COALESCE(SUM(lp.total_price), 0) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT TOPOrders.o_orderkey) > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS order_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN AggregatedPrices lp ON lp.l_orderkey = ps.ps_partkey
LEFT JOIN TopOrders ON TopOrders.o_orderkey = lp.l_orderkey
WHERE p.p_size BETWEEN 5 AND 20 
AND p.p_retailprice IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_brand, s.s_name, n.n_name
HAVING SUM(lp.total_price) IS NOT NULL
OR COUNT(s.s_suppkey) = 0
ORDER BY total_revenue DESC NULLS LAST;