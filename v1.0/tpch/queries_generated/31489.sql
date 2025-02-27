WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_sales DESC
    LIMIT 10

    UNION ALL

    SELECT 
        s.s_suppkey AS c_custkey, 
        s.s_name AS c_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL AND ps.ps_supplycost IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
)

SELECT 
    COALESCE(s.c_custkey, s.c_name) AS entity_key,
    CASE 
        WHEN s.total_sales IS NOT NULL THEN 'Customer' 
        ELSE 'Supplier' 
    END AS entity_type,
    SUM(s.total_sales) AS total_sales
FROM 
    SalesCTE s
LEFT JOIN 
    region r ON r.r_regionkey = 
    (SELECT n.n_regionkey 
     FROM nation n 
     WHERE n.n_nationkey IN 
           (SELECT DISTINCT c.c_nationkey 
            FROM customer c 
            WHERE c.c_custkey = s.c_custkey))
GROUP BY 
    COALESCE(s.c_custkey, s.c_name), 
    entity_type
ORDER BY 
    total_sales DESC
LIMIT 5;
