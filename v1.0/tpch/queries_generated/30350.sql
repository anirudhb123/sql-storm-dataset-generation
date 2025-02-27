WITH RECURSIVE OrderCTE AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    INNER JOIN OrderCTE cte ON o.o_custkey = cte.o_custkey 
    WHERE o.o_orderdate > cte.o_orderdate
),
AggregatedSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
DenseRankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr,
           CASE 
               WHEN p.p_size IS NULL THEN 'Size Not Available' 
               ELSE CAST(p.p_size AS VARCHAR(10))
           END AS size_status
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FinalOutput AS (
    SELECT cs.c_name, cs.total_spent, d.price_rank,
           fp.p_name, asp.total_cost 
    FROM CustomerSummary cs
    LEFT JOIN DenseRankedOrders d ON cs.c_custkey = d.o_orderkey
    LEFT JOIN FilteredParts fp ON cs.c_custkey = fp.p_partkey
    LEFT JOIN AggregatedSupplier asp ON fp.p_partkey = asp.ps_partkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
)
SELECT COALESCE(fo.c_name, 'Unknown Customer') AS customer_name,
       fo.total_spent, 
       fo.price_rank, 
       COALESCE(fo.p_name, 'No Part') AS part_name,
       COALESCE(fo.total_cost, 0) AS aggregate_cost
FROM FinalOutput fo
ORDER BY fo.total_spent DESC, fo.price_rank ASC;
