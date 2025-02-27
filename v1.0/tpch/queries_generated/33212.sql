WITH RECURSIVE RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
    UNION ALL
    SELECT 
        r.r_name AS region_name,
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        EXISTS (
            SELECT 1 
            FROM lineitem li 
            WHERE li.l_orderkey = o.o_orderkey 
            AND li.l_returnflag = 'R'
        )
    GROUP BY 
        r.r_name
), 
CustomerRank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    r.region_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT cr.c_custkey) AS active_customers,
    MAX(cr.total_spent) AS max_spending_customer,
    CASE 
        WHEN MAX(cr.total_spent) IS NULL THEN 'NO SALES'
        ELSE 'SALES RECORD EXISTS'
    END AS sales_record_status
FROM 
    RegionalSales rs
LEFT JOIN 
    region r ON r.r_name = rs.region_name
LEFT JOIN 
    CustomerRank cr ON cr.rank_within_nation = 1
GROUP BY 
    r.region_name
ORDER BY 
    total_sales DESC;
