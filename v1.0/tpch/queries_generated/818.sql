WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_name,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        customerOrders co
    JOIN 
        customer c ON co.c_name = c.c_name
    WHERE 
        co.order_count > 5
)
SELECT 
    pc.p_name,
    pc.p_brand,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    tc.total_spent,
    COALESCE(RS.total_sales, 0) AS total_sales,
    CASE 
        WHEN tc.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    part pc
LEFT JOIN 
    partsupp ps ON pc.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
LEFT JOIN 
    RankedSales RS ON l.l_orderkey = RS.l_orderkey
JOIN 
    TopCustomers tc ON tc.customer_rank <= 10
GROUP BY 
    pc.p_name, pc.p_brand, tc.total_spent, RS.total_sales
HAVING 
    SUM(ps.ps_supplycost) > 5000
ORDER BY 
    total_supply_cost DESC, tc.total_spent DESC;
