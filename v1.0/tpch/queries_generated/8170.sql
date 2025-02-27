WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_mktsegment
    FROM customer c
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, l.l_partkey, SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, l.l_partkey
)
SELECT 
    si.s_name, 
    ni.n_name AS nation_name, 
    ci.c_name AS customer_name, 
    od.o_orderkey, 
    od.o_orderdate, 
    od.total_quantity, 
    SUM(si.total_cost) AS supplier_total_cost, 
    SUM(od.o_totalprice) AS order_total_price
FROM 
    SupplierInfo si
JOIN 
    NationInfo ni ON si.s_nationkey = ni.n_nationkey
JOIN 
    CustomerInfo ci ON ci.c_nationkey = ni.n_nationkey
JOIN 
    OrderDetails od ON od.l_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = si.s_suppkey)
GROUP BY 
    si.s_name, ni.n_name, ci.c_name, od.o_orderkey, od.o_orderdate, od.total_quantity
ORDER BY 
    supplier_total_cost DESC, order_total_price DESC
LIMIT 100;
