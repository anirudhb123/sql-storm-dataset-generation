WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_type, p.p_retailprice,
           CASE 
               WHEN p.p_size IS NULL THEN 'UNKNOWN'
               ELSE CAST(p.p_size AS VARCHAR)
           END AS size_description
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
JoinSummary AS (
    SELECT p.p_name, ps.ps_supplycost, COALESCE(l.l_quantity, 0) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM FilteredParts p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_name, ps.ps_supplycost
)
SELECT c.c_name, so.s_name, p.size_description, COUNT(DISTINCT co.o_orderkey) AS order_count,
       SUM(js.total_revenue) AS total_revenue
FROM CustomerOrders co
JOIN RankedSuppliers so ON co.c_custkey = so.s_suppkey
LEFT JOIN JoinSummary js ON js.p_name = co.o_orderkey::TEXT  -- Bizarre type coercion for join
JOIN FilteredParts p ON p.p_partkey = (SELECT MAX(pl.p_partkey) 
                                         FROM part pl WHERE pl.p_name LIKE '%' || COALESCE(NULLIF(co.c_name, ''), 'DEFAULT') || '%')
                                         LIMIT 1)
WHERE so.rank_acctbal < 5 AND (p.p_retailprice IS NOT NULL OR co.o_totalprice < 1000.00)
GROUP BY c.c_name, so.s_name, p.size_description
HAVING SUM(js.total_revenue) > 10000
ORDER BY order_count DESC, total_revenue DESC
LIMIT 10;
