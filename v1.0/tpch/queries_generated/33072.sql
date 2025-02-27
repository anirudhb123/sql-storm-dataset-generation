WITH RECURSIVE RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
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
        n.n_nationkey, n.n_name
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(rs.total_sales) AS regional_total
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        RegionalSales rs ON n.n_nationkey = rs.nation_name
    GROUP BY 
        r.r_name
    HAVING 
        SUM(rs.total_sales) IS NOT NULL
    ORDER BY 
        regional_total DESC
    LIMIT 5
)
SELECT 
    o.o_orderkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS order_status,
    r.r_name AS region_name
FROM 
    orders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '2023-01-01'
    AND o.o_orderdate < '2023-10-01'
GROUP BY 
    o.o_orderkey, c.c_name, o.o_orderstatus, r.r_name
HAVING 
    order_total > (
        SELECT AVG(order_total)
        FROM (
            SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS order_total
            FROM 
                orders o2
            JOIN 
                lineitem l2 ON o2.o_orderkey = l2.l_orderkey
            GROUP BY 
                o2.o_orderkey
        ) AS avg_subquery
    )
ORDER BY 
    order_total DESC, o.o_orderkey;
