WITH RECURSIVE region_stats AS (
    SELECT r_regionkey, r_name, COUNT(n_nationkey) AS nation_count
    FROM region
    JOIN nation ON region.r_regionkey = nation.n_regionkey
    GROUP BY r_regionkey, r_name
),
avg_order_value AS (
    SELECT c_nationkey, AVG(o_totalprice) AS avg_price
    FROM customer
    JOIN orders ON customer.c_custkey = orders.o_custkey
    GROUP BY c_nationkey
),
total_supply AS (
    SELECT ps_partkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_partkey
),
ranked_orders AS (
    SELECT o_orderkey, o_totalprice, DENSE_RANK() OVER (ORDER BY o_totalprice DESC) AS price_rank
    FROM orders
),
supplier_summary AS (
    SELECT s.s_nationkey, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
)
SELECT 
    rs.r_name,
    COALESCE(SUM(oso.o_totalprice), 0) AS total_order_value,
    COALESCE(ss.total_acctbal, 0) AS total_supplier_balance,
    COALESCE(AVG(a.avg_price), 0) AS average_order_price,
    COALESCE(ts.total_cost, 0) AS total_supply_cost,
    RANK() OVER (ORDER BY COALESCE(SUM(oso.o_totalprice), 0) DESC) AS region_rank
FROM 
    region_stats rs
LEFT JOIN 
    order_summary oso ON rs.r_regionkey = oso.c_nationkey
LEFT JOIN 
    supplier_summary ss ON rs.r_regionkey = ss.s_nationkey
LEFT JOIN 
    avg_order_value a ON a.c_nationkey = rs.r_regionkey
LEFT JOIN 
    total_supply ts ON ts.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp))
GROUP BY 
    rs.r_name, ss.total_acctbal
ORDER BY 
    region_rank;
