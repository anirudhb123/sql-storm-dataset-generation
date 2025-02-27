WITH Rich_Customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
Top_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
Recent_Orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, o.o_orderdate, l.l_shipdate
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATEADD(month, -3, CURRENT_DATE)
)
SELECT rc.nation_name, rc.c_name AS customer_name, rc.c_acctbal, 
       ts.s_name AS supplier_name, ts.total_supply_cost,
       ro.o_orderkey, ro.o_totalprice, ro.o_orderdate, ro.l_shipdate
FROM Rich_Customers rc
JOIN Top_Suppliers ts ON ts.total_supply_cost > 10000
JOIN Recent_Orders ro ON rc.c_name = ro.c_name
WHERE rc.c_acctbal > 1000
ORDER BY rc.nation_name, rc.c_acctbal DESC, ro.o_orderdate DESC;
