WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS nation_total_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedNations AS (
    SELECT 
        n.n_name,
        ns.nation_total_sales,
        RANK() OVER (ORDER BY ns.nation_total_sales DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        NationSales ns ON n.n_nationkey = ns.n_nationkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    COALESCE(rn.sales_rank, 'Not Ranked') AS sales_rank,
    SUM(l.l_quantity) AS total_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    RankedNations rn ON s.s_nationkey = rn.n_nationkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50.00)
    AND (p.p_container LIKE '%BOX%' OR p.p_container IS NULL)
GROUP BY 
    p.p_name, p.p_mfgr, p.p_brand, rn.sales_rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_quantity DESC;
