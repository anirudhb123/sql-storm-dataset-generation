WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey
), ordered_nations AS (
    SELECT 
        n.n_name,
        ns.total_sales,
        ns.sales_rank,
        RANK() OVER (ORDER BY ns.total_sales DESC) as total_sales_rank
    FROM 
        nation_sales ns
    JOIN 
        nation n ON ns.n_nationkey = n.n_nationkey
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_orderdate,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COALESCE(ordered.total_sales, 0) AS nation_total_sales,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_description,
    COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS item_count,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', l.l_quantity, ')'), ', ') OVER (PARTITION BY o.o_orderkey) AS item_details
FROM 
    orders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    ordered_nations ordered ON ordered.total_sales_rank = 1 AND ordered.total_sales > 10000
LEFT JOIN 
    nation n ON n.n_nationkey = COALESCE(l.l_suppkey, -1)
WHERE 
    (o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' OR o.o_orderstatus IS NULL)
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
ORDER BY 
    o.o_orderdate DESC, o.o_orderkey;
