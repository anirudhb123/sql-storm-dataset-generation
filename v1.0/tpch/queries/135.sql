WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name, total_sales 
    FROM 
        RegionalSales 
    WHERE 
        sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tr.region_name,
    co.c_custkey,
    co.c_name,
    co.total_spent,
    co.order_count,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    TopRegions tr
LEFT JOIN 
    CustomerOrders co ON tr.region_name = (SELECT r.r_name 
                                           FROM region r 
                                           JOIN nation n ON r.r_regionkey = n.n_regionkey 
                                           JOIN supplier s ON n.n_nationkey = s.s_nationkey 
                                           WHERE s.s_suppkey = co.c_custkey) 
ORDER BY 
    tr.total_sales DESC, co.order_count DESC
