WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_orders > 10
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_quantity_sold > 100
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderpriority
    FROM orders o
    WHERE o.o_totalprice > 1000
)
SELECT 
    cu.c_name AS Customer_Name, 
    st.s_name AS Supplier_Name, 
    pd.p_name AS Product_Name, 
    ho.o_orderkey AS Order_Number, 
    ho.o_totalprice AS Order_Total, 
    ho.o_orderdate AS Order_Date, 
    ho.o_orderpriority AS Order_Priority
FROM HighValueOrders ho
JOIN CustomerOrders cu ON ho.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cu.c_custkey)
JOIN TopSuppliers st ON ho.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l JOIN partsupp ps ON l.l_partkey = ps.ps_partkey WHERE ps.ps_suppkey = st.s_suppkey)
JOIN ProductDetails pd ON ho.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey)
ORDER BY ho.o_totalprice DESC, cu.c_name, st.s_name;
