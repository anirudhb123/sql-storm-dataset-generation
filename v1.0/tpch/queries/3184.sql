
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ss.total_sales) AS total_sales_by_nation
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_sales_by_nation,
    RANK() OVER (PARTITION BY r.r_name ORDER BY ns.total_sales_by_nation DESC) AS sales_rank
FROM 
    region r
JOIN 
    NationSummary ns ON ns.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = r.r_regionkey)
ORDER BY 
    r.r_name, sales_rank;
