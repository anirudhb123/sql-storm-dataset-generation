WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS nation_sales,
        COUNT(ss.order_count) AS nation_order_count
    FROM 
        nation n
    LEFT JOIN 
        SupplierSales ss ON ss.s_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = n.n_nationkey)
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedNations AS (
    SELECT 
        n.n_name,
        n.nation_sales,
        n.nation_order_count,
        RANK() OVER (ORDER BY n.nation_sales DESC) AS sales_rank
    FROM 
        NationSales n
)
SELECT 
    p.p_name,
    COALESCE(r.n_name, 'Unknown') AS nation,
    r.nation_sales,
    r.nation_order_count
FROM 
    part p
LEFT JOIN 
    RankedNations r ON r.nation_sales > p.p_retailprice
WHERE 
    p.p_size BETWEEN 1 AND 10
    AND r.sales_rank <= 5
ORDER BY 
    p.p_partkey;
