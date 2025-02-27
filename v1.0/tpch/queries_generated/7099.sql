WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales
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
        o.o_orderstatus = 'O'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)

SELECT 
    tr.region_name,
    tr.total_sales,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM 
    TopRegions tr
JOIN 
    supplier s ON EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_suppkey = s.s_suppkey
        AND EXISTS (
            SELECT 1
            FROM part p
            WHERE p.p_partkey = ps.ps_partkey
            AND tr.region_name = (
                SELECT r.r_name 
                FROM region r 
                JOIN nation n ON r.r_regionkey = n.n_regionkey
                WHERE n.n_nationkey = s.s_nationkey
            )
        )
    )
GROUP BY 
    tr.region_name, tr.total_sales
HAVING 
    total_sales > 100000
ORDER BY 
    tr.total_sales DESC;
