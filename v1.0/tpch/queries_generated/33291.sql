WITH RECURSIVE order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
ranking AS (
    SELECT *, 
           RANK() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rn
    FROM supplier_details
    WHERE total_supply_cost > 0
),
special_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ntile(10) OVER (ORDER BY o.o_totalprice DESC) AS price_quartile
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
)
SELECT 
    r.nation_name, 
    r.s_name, 
    r.total_supply_cost, 
    st.o_orderkey, 
    st.o_orderdate, 
    st.o_totalprice, 
    ot.total_revenue
FROM ranking r
LEFT JOIN special_orders st ON r.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps 
                                               WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                       FROM part p 
                                                                       WHERE p.p_size > 10))
LEFT JOIN order_totals ot ON st.o_orderkey = ot.o_orderkey
WHERE r.rn <= 5
ORDER BY r.nation_name, r.total_supply_cost DESC, st.o_orderdate;
