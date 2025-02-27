WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    LEFT JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        customer c ON c.c_custkey = o.o_custkey
    WHERE 
        l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        r.r_name
),
HighSpenders AS (
    SELECT 
        c.c_nationkey,
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
            WHERE c2.c_mktsegment = c.c_mktsegment
        )
)
SELECT 
    rs.region_name,
    rs.total_sales,
    rs.customer_count,
    rs.avg_supplier_balance,
    COUNT(DISTINCT hs.c_custkey) AS high_spender_count
FROM 
    RegionalSales rs
LEFT JOIN 
    HighSpenders hs ON hs.c_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        JOIN region r ON n.n_regionkey = r.r_regionkey 
        WHERE r.r_name = rs.region_name
    )
GROUP BY 
    rs.region_name, rs.total_sales, rs.customer_count, rs.avg_supplier_balance
HAVING 
    rs.total_sales > (
        SELECT AVG(total_sales) 
        FROM RegionalSales
    )
ORDER BY 
    rs.total_sales DESC
LIMIT 10;
