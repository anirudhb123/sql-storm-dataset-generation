WITH RECURSIVE RegionSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
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
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) + (SELECT COALESCE(SUM(total_sales), 0) FROM RegionSales)
    FROM 
        region r
    JOIN 
        RegionSales rs ON rs.r_regionkey = r.r_regionkey
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
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rs.r_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_region_sales,
    COALESCE(SUM(co.total_spending), 0) AS total_customer_spending,
    rdf.supplier_name,
    rdf.supplier_rank
FROM 
    RegionSales rs
FULL OUTER JOIN 
    CustomerOrders co ON rs.r_regionkey = co.c_custkey
CROSS JOIN 
    (SELECT s.s_name AS supplier_name, rss.supplier_rank
     FROM RankedSuppliers rss 
     WHERE rss.supplier_rank <= 5) rdf
GROUP BY 
    rs.r_name, rdf.supplier_name, rdf.supplier_rank
HAVING 
    total_region_sales > 100000 OR total_customer_spending IS NOT NULL
ORDER BY 
    total_region_sales DESC, total_customer_spending DESC;
