WITH SupplyCosts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        (l.l_extendedprice * (1 - l.l_discount)) AS sales_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    SUM(sc.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    AVG(co.total_spent) AS avg_spent_per_customer,
    SUM(od.sales_price) AS total_sales
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplyCosts sc ON s.s_suppkey = sc.p_partkey
JOIN 
    CustomerOrders co ON co.orders_count > 0
JOIN 
    OrderDetails od ON od.l_partkey = sc.p_partkey
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;
