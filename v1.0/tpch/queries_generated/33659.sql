WITH RECURSIVE CTE_Supplier AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, cs.level + 1
    FROM supplier s
    JOIN CTE_Supplier cs ON s.s_nationkey = cs.s_nationkey 
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    ) AND cs.level < 3
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 5000
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_cost, COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
DenseRankPart AS (
    SELECT p.p_partkey, p.p_name, DENSE_RANK() OVER(ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation,
    rg.r_name AS region,
    c.c_name AS customer,
    SUM(o.o_totalprice) AS total_value,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
    DENSE_RANK() OVER(ORDER BY SUM(o.o_totalprice) DESC) AS total_order_rank,
    p.p_name,
    p.p_retailprice,
    rnk.price_rank
FROM nation n
JOIN region rg ON n.n_regionkey = rg.r_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN HighValueOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplierStats s ON s.ps_partkey IN (SELECT p_partkey FROM part WHERE p_size BETWEEN 10 AND 20)
LEFT JOIN DenseRankPart rnk ON rnk.p_partkey = s.ps_partkey
LEFT JOIN CTE_Supplier cs ON cs.s_nationkey = n.n_nationkey
WHERE n.n_nationkey IS NOT NULL
GROUP BY n.n_name, rg.r_name, c.c_name, p.p_name, rnk.price_rank
HAVING SUM(o.o_totalprice) > 10000
ORDER BY total_order_rank, total_value DESC;
