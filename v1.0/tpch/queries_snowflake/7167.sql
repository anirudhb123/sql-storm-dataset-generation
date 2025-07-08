WITH Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Customer_Purchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Order_Details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
Top_Suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_supply_value
    FROM 
        Supplier_Summary ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_value = (SELECT MAX(total_supply_value) FROM Supplier_Summary)
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cp.total_spent
    FROM 
        Customer_Purchases cp
    JOIN 
        customer c ON cp.c_custkey = c.c_custkey
    WHERE 
        cp.total_spent = (SELECT MAX(total_spent) FROM Customer_Purchases)
)
SELECT 
    ts.s_suppkey, 
    ts.s_name AS supplier_name,
    tc.c_custkey, 
    tc.c_name AS customer_name,
    SUM(od.revenue) AS total_revenue_generated
FROM 
    Top_Suppliers ts
CROSS JOIN 
    Top_Customers tc
JOIN 
    Order_Details od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
GROUP BY 
    ts.s_suppkey, ts.s_name, tc.c_custkey, tc.c_name
ORDER BY 
    total_revenue_generated DESC;
