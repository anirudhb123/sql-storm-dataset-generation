WITH RECURSIVE RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
    UNION ALL
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= (SELECT MAX(o.o_orderdate) FROM orders o WHERE o.o_orderstatus = 'F')
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
),
OrderedSales AS (
    SELECT 
        region_name,
        SUM(total_sales) AS total_region_sales
    FROM 
        RegionalSales
    GROUP BY 
        region_name
),
RankedRegions AS (
    SELECT 
        region_name,
        total_region_sales,
        RANK() OVER (ORDER BY total_region_sales DESC) AS sales_rank
    FROM 
        OrderedSales
)
SELECT 
    rr.region_name,
    rr.total_region_sales,
    COALESCE(NULLIF(rr.sales_rank, 1), 'No Ranking') AS rank_info
FROM 
    RankedRegions rr
WHERE 
    rr.sales_rank <= 5
ORDER BY 
    rr.total_region_sales DESC;
