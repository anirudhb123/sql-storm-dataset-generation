WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_comment IS NOT NULL AND LENGTH(s.s_comment) > 10
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey AND sh.level < 3
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        os.total_revenue,
        RANK() OVER (PARTITION BY os.unique_parts ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
    JOIN orders o ON os.o_orderkey = o.o_orderkey
    WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM OrderSummary)
)
SELECT
    ph.p_name,
    ph.p_retailprice,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'Y' THEN l.l_quantity ELSE 0 END) AS total_returned,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (Level:', sh.level, ')'), '; ') AS suppliers_info
FROM FilteredParts ph
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON ph.p_partkey = l.l_partkey
JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE ph.size_category = 'Medium' AND r.r_name IS NOT NULL
GROUP BY ph.p_name, ph.p_retailprice, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10 OR SUM(l.l_discount) < 5
ORDER BY ph.p_retailprice DESC, total_orders ASC
LIMIT 100;
