WITH RECURSIVE eligible_customers AS (
    SELECT c_custkey, c_name, c_acctbal, c_mktsegment
    FROM customer
    WHERE c_acctbal > (
        SELECT AVG(c_acctbal)
        FROM customer
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment
    FROM customer c
    JOIN eligible_customers ec ON c.c_custkey < ec.c_custkey
    WHERE c.c_acctbal > ec.c_acctbal
),
high_value_part AS (
    SELECT p_partkey, p_name, p_retailprice, p_mfgr
    FROM part
    WHERE p_retailprice > (
        SELECT AVG(p_retailprice) * 1.1
        FROM part
    )
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'P')
    AND EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0.05
    )
),
customer_order_count AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM filtered_orders o
    GROUP BY o.o_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 2
),
supplier_part_info AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT ec.c_custkey, ec.c_name, ec.c_acctbal, ec.c_mktsegment,
       COALESCE(p.p_name, 'No High Value Parts') AS high_value_part_name,
       COALESCE(o.o_totalprice, 0) AS order_total,
       s.supplier_count, s.total_supply_cost
FROM eligible_customers ec
LEFT JOIN filtered_orders o ON ec.c_custkey = o.o_orderkey
LEFT JOIN high_value_part p ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN customer_order_count co ON ps.ps_suppkey = co.o_custkey
)
LEFT JOIN supplier_part_info s ON s.ps_partkey = p.p_partkey
WHERE ec.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
  AND (s.supplier_count > 3 OR s.total_supply_cost IS NULL)
ORDER BY ec.c_acctbal DESC, o.o_totalprice NULLS LAST;
