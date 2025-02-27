WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
RankedSales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesCTE
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ns.n_name AS supplier_nation, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS order_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSales o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 20 
    AND p.p_retailprice < 100.00
GROUP BY 
    p.p_partkey, p.p_name, ns.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000.00
ORDER BY 
    total_revenue DESC
LIMIT 10;
