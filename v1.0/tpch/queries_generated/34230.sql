WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON sc.ps_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > sc.ps_availqty
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PriceRanking AS (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS price_rank
    FROM partsupp ps
),
AggregateSummary AS (
    SELECT r.r_name, SUM(COALESCE(sc.ps_availqty, 0)) AS total_available
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    GROUP BY r.r_name
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(ps.p_name, 'N/A') AS product_name,
    cs.total_spent,
    as.total_available,
    pr.price_rank,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE CASE 
            WHEN cs.total_spent > 10000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END 
    END AS customer_category
FROM CustomerOrderSummary cs
FULL OUTER JOIN PriceRanking pr ON pr.ps_partkey = cs.c_custkey
FULL OUTER JOIN AggregateSummary as ON pr.ps_partkey = as.total_available
LEFT JOIN part ps ON pr.ps_partkey = ps.p_partkey
WHERE (cs.total_spent IS NOT NULL OR pr.price_rank IS NOT NULL)
AND (as.total_available > 0 OR NULLIF(cs.total_spent, 0) IS NOT NULL)
ORDER BY cs.total_spent DESC, as.total_available ASC;
