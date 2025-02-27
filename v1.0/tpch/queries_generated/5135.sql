WITH Supplier_Parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost 
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000
),
High_Value_Orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_custkey, c.c_name 
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 5000 AND o.o_orderdate >= '2023-01-01'
),
Order_Supplier_Part AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice, sp.s_name, sp.p_name 
    FROM lineitem l
    JOIN High_Value_Orders hvo ON l.l_orderkey = hvo.o_orderkey
    JOIN Supplier_Parts sp ON l.l_suppkey = sp.s_suppkey AND l.l_partkey = sp.ps_partkey
)
SELECT o.c_name, sp.p_name, SUM(os.l_quantity) AS total_quantity, SUM(os.l_extendedprice) AS total_revenue 
FROM Order_Supplier_Part os
JOIN High_Value_Orders o ON os.l_orderkey = o.o_orderkey
GROUP BY o.c_name, sp.p_name
ORDER BY total_revenue DESC, o.c_name ASC
LIMIT 10;
