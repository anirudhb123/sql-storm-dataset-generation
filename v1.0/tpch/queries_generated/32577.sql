WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS lvl
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.lvl + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    WHERE oh.o_orderkey IS NOT NULL AND oh.lvl < 5
),
ordered_suppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, os.total_supply_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY os.total_supply_cost DESC) AS supply_rank
    FROM supplier s
    LEFT JOIN ordered_suppliers os ON s.s_suppkey = os.ps_suppkey
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    co.c_name AS customer_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(co.order_count, 0) AS order_count,
    r.s_name AS supplier_name,
    r.total_supply_cost,
    r.supply_rank
FROM customer_order_summary co
FULL OUTER JOIN ranked_suppliers r ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = r.s_nationkey)
WHERE co.total_spent > 1000 OR r.total_supply_cost IS NOT NULL
ORDER BY co.total_spent DESC, r.total_supply_cost DESC;
