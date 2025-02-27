WITH RECURSIVE order_dates AS (
    SELECT o_orderdate, o_orderkey
    FROM orders
    WHERE o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    UNION ALL
    SELECT o_orderdate + INTERVAL '1 day', o_orderkey
    FROM orders
    JOIN order_dates ON orders.o_orderkey = order_dates.o_orderkey
    WHERE o_orderdate < '1997-01-01'
), high_value_customers AS (
    SELECT c_custkey, c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
), part_suppliers AS (
    SELECT ps.partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
), ranked_lineitems AS (
    SELECT l.*, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
           SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS total_order_value
    FROM lineitem l
), non_null_parts AS (
    SELECT p.p_partkey, p.p_retailprice, COALESCE(p.p_comment, 'No Comment') AS part_comment
    FROM part p
    WHERE p.p_size IS NOT NULL
), outer_joined_data AS (
    SELECT r.r_name, 
           COALESCE(hvc.total_spent, 0) AS total_spent, 
           COALESCE(ps.total_supply_cost, 0) AS supply_cost
    FROM region r
    LEFT JOIN high_value_customers hvc ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_nationkey = hvc.c_custkey
    )
    FULL OUTER JOIN part_suppliers ps ON ps.partkey IN (
        SELECT p.p_partkey 
        FROM non_null_parts p 
        WHERE p.p_retailprice BETWEEN 100 AND 500
    )
)
SELECT od.o_orderdate,
       r.r_name,
       ROUND(AVG(od.total_spent), 2) AS avg_spent_per_day,
       SUM(r.supply_cost) AS total_supply_cost
FROM order_dates od
JOIN outer_joined_data r ON od.orderkey = r.total_spent
GROUP BY od.o_orderdate, r.r_name
HAVING SUM(r.supply_cost) IS NOT NULL
ORDER BY od.o_orderdate DESC, avg_spent_per_day DESC
LIMIT 10;
