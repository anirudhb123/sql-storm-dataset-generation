WITH RECURSIVE Supply_CTE AS (
    SELECT ps_partkey, SUM(ps_availqty) AS total_availqty
    FROM partsupp
    GROUP BY ps_partkey
    HAVING SUM(ps_availqty) > 100
),
Qualified_Customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
Recent_Orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 1
               ELSE 0 
           END AS is_filled
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
),
Supplier_Info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING total_supplycost > 10000
)
SELECT DISTINCT 
    p.p_name,
    rc.c_name AS customer_name,
    si.s_name AS supplier_name,
    COALESCE(ro.o_totalprice, 0) AS total_order_price,
    si.total_supplycost AS supplier_total_cost,
    CASE 
        WHEN rc.rank <= 5 THEN 'Premium'
        ELSE 'Standard' 
    END AS customer_tier,
    SQUARE(SUM(l.l_discount)) AS discount_squared,
    COUNT(DISTINCT l.l_orderkey) AS order_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN Recent_Orders ro ON l.l_orderkey = ro.o_orderkey
JOIN Qualified_Customers rc ON ro.o_custkey = rc.c_custkey
INNER JOIN Supplier_Info si ON l.l_suppkey = si.s_suppkey
LEFT JOIN nation n ON si.s_nationkey = n.n_nationkey
WHERE p.p_retailprice BETWEEN 50 AND 200
  AND n.n_name IS NOT NULL
GROUP BY p.p_name, rc.c_name, si.s_name, si.total_supplycost
HAVING COUNT(DISTINCT l.l_orderkey) > 3
   AND SUM(l.l_extendedprice * (1 - l.l_discount)) < 5000
ORDER BY discount_squared DESC, total_order_price DESC;
