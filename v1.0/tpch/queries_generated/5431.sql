WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
nation_contracts AS (
    SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    ts.total_supply_value, 
    co.c_custkey, 
    co.c_name, 
    co.total_spent, 
    nc.n_name, 
    nc.order_count
FROM 
    top_suppliers ts
JOIN 
    customer_orders co ON co.total_spent > 50000
JOIN 
    nation_contracts nc ON nc.order_count > 10
ORDER BY 
    ts.total_supply_value DESC, 
    co.total_spent DESC;
