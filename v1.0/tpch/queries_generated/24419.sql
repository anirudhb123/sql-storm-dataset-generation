WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
           rank() OVER (ORDER BY o.o_totalprice ASC) AS total_price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate <= DATE '2023-12-31'
),
supply_cost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL AND ps.ps_supplycost >= (
        SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_availqty > 0
    )
    GROUP BY ps.ps_partkey
),
customer_extensions AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal + COALESCE(NULLIF(c.c_acctbal, 0), 100) AS adjusted_acctbal
    FROM customer c
    WHERE c.c_mktsegment IN ('BUILDING', 'AUTO') OR [TRUE]
)
SELECT 
    n.n_name,
    s.s_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(ce.adjusted_acctbal) AS avg_customer_balance,
    DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer ce ON o.o_custkey = ce.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN supply_cost sc ON ps.ps_partkey = sc.ps_partkey
WHERE n.n_regionkey IN (SELECT n_regionkey FROM nation_hierarchy)
  AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY n.n_name, s.s_name, p.p_name
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY total_revenue DESC, n.n_name ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
