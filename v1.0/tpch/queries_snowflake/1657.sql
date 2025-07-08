
WITH RegionSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r 
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 10000
)

SELECT 
    rs.region,
    COALESCE(hvc.c_name, 'No High Value Customers') AS high_value_customer,
    COALESCE(cos.total_spent, 0) AS total_spent_by_customer,
    rs.total_sales AS total_sales_in_region
FROM 
    RegionSales rs
LEFT JOIN 
    HighValueCustomers hvc ON true = (
        SELECT 
            COUNT(*) > 0
        FROM 
            nation n
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
        JOIN 
            customer c ON o.o_custkey = c.c_custkey
        WHERE 
            c.c_custkey = hvc.c_custkey
    )
LEFT JOIN 
    CustomerOrderSummary cos ON hvc.c_custkey = cos.c_custkey
ORDER BY 
    rs.total_sales DESC;
