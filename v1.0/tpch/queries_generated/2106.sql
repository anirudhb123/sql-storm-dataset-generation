WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
        AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        co.total_spent,
        rs.total_sales
    FROM 
        CustomerOrders co
    JOIN 
        nation n ON co.c_nationkey = n.n_nationkey
    JOIN 
        RegionalSales rs ON n.n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'NORTH AMERICA')
    WHERE 
        co.rank <= 10
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    tc.total_sales,
    COALESCE((SELECT COUNT(*) FROM orders o WHERE o.o_custkey = tc.c_custkey AND o.o_orderstatus = 'F'), 0) AS completed_orders,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'Platinum'
        WHEN tc.total_spent > 500 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_spent DESC;

