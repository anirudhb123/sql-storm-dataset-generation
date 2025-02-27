WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS order_year,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o_o_orderdate >= DATE '2020-01-01' AND o_o_orderdate < DATE '2023-01-01'
    GROUP BY 
        order_year
), 
region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ys.total_sales) AS region_total_sales
    FROM 
        yearly_sales ys
    JOIN 
        customer c ON EXISTS (
            SELECT 1
            FROM nation n 
            WHERE n.n_nationkey = c.c_nationkey 
            AND n.n_regionkey = (
                SELECT r_regionkey 
                FROM region r 
                WHERE r.r_name IN ('AMERICA', 'EUROPE')
            )
        )
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name
), 
supplier_part_sales AS (
    SELECT 
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        s.s_name AS supplier_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_brand = 'Brand#23'
    GROUP BY 
        p.p_name, s.s_name
)

SELECT 
    r.region_name,
    COALESCE(r.region_total_sales, 0) AS total_sales_by_region,
    CAST(SUM(sps.total_sales) AS decimal(12, 2)) AS supplier_part_total_sales
FROM 
    region_sales r
LEFT JOIN 
    supplier_part_sales sps ON r.region_name = sps.supplier_name
GROUP BY 
    r.region_name
ORDER BY 
    total_sales_by_region DESC;
