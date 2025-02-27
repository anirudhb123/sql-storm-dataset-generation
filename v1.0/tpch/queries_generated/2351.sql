WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        n.n_name
),
TopSellingItems AS (
    SELECT 
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS item_sales
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
        AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        p.p_name
    ORDER BY 
        item_sales DESC
    LIMIT 10
)
SELECT 
    r.nation_name,
    COALESCE(p.p_name, 'No Top Item') AS top_item,
    r.total_sales,
    ti.item_sales
FROM 
    RegionalSales r
LEFT JOIN 
    TopSellingItems ti ON r.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name = ti.p_name))))
LEFT JOIN 
    part p ON p.p_name = ti.p_name
WHERE 
    r.total_sales > (SELECT AVG(total_sales) FROM RegionalSales)
ORDER BY 
    r.total_sales DESC, ti.item_sales DESC;
