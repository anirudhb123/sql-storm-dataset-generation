WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    p.p_name AS product_name,
    sc.total_cost,
    co.order_count,
    co.total_spent,
    ps.total_quantity,
    ps.total_revenue
FROM 
    SupplierCosts sc
JOIN 
    CustomerOrders co ON co.order_count > 5
JOIN 
    ProductSales ps ON ps.total_revenue > 5000
JOIN 
    supplier s ON sc.s_suppkey = s.s_suppkey
JOIN 
    customer c ON co.c_custkey = c.c_custkey
JOIN 
    part p ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey)
WHERE 
    s.s_acctbal > 1000
ORDER BY 
    total_spent DESC, total_revenue DESC;
