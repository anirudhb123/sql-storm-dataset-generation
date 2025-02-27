WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
    GROUP BY 
        r.r_name
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 1
)
SELECT 
    r.region_name,
    rs.total_sales,
    cs.customer_total,
    tc.c_custkey AS top_customer_custkey,
    (CASE 
        WHEN cs.customer_total IS NULL THEN 'No sales'
        WHEN cs.customer_total = 0 THEN 'Zero sales'
        ELSE 'Some sales'
     END) AS sales_status
FROM 
    RegionalSales rs
LEFT JOIN 
    CustomerSales cs ON rs.region_name = (
        SELECT DISTINCT 
            r2.r_name 
        FROM 
            region r2
        JOIN 
            nation n2 ON r2.r_regionkey = n2.n_regionkey
        JOIN 
            supplier s2 ON n2.n_nationkey = s2.s_nationkey
        JOIN 
            partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey
        JOIN 
            part p2 ON ps2.ps_partkey = p2.p_partkey
        JOIN 
            lineitem l2 ON p2.p_partkey = l2.l_partkey
        JOIN 
            orders o2 ON l2.l_orderkey = o2.o_orderkey
        WHERE 
            o2.o_orderstatus IN ('O', 'F') 
            AND cs.customer_total = (SELECT MAX(customer_total) FROM CustomerSales cs2 WHERE cs2.c_custkey = cs.c_custkey)
            AND r2.r_name IS NOT NULL
    )
LEFT JOIN 
    TopCustomers tc ON cs.c_custkey = tc.c_custkey
ORDER BY 
    total_sales DESC, sales_status ASC;
