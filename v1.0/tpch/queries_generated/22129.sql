WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), HighestAvgPrice AS (
    SELECT 
        ps.ps_partkey, 
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        AVG(l.l_extendedprice * (1 - l.l_discount)) > 
        (SELECT 
            AVG(l_extendedprice) 
         FROM 
            lineitem 
         WHERE 
            l_discount BETWEEN 0.05 AND 0.10)
), FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity, 
        CASE 
            WHEN SUM(l.l_quantity) > 100 THEN 'High'
            WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS quantity_category 
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.rnk,
    s.s_name,
    s.s_acctbal,
    p.p_name,
    COALESCE(o.quantity_category, 'No Orders') AS quantity_category,
    h.avg_price
FROM 
    RankedSuppliers s
LEFT JOIN 
    HighestAvgPrice h ON s.s_suppkey = h.ps_partkey
LEFT JOIN 
    part p ON p.p_partkey = h.ps_partkey
LEFT JOIN 
    FilteredOrders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM FilteredOrders o2 WHERE o2.total_quantity = o.total_quantity)
WHERE 
    s.rnk = 1 
    OR (s.s_acctbal IS NULL AND s.s_name LIKE 'A%')
ORDER BY 
    h.avg_price DESC NULLS LAST, 
    s.s_name ASC;
