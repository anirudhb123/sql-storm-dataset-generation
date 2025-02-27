WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        *
    FROM 
        RankedSuppliers
    WHERE 
        rn <= 5
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    ns.n_name AS nation_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(o.total_revenue) AS average_order_revenue,
    COALESCE(MAX(s.s_name), 'No Supplier') AS top_supplier_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    OrderStatistics o ON o.o_orderkey IN (
        SELECT 
            o.orderkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderstatus = 'F'
            AND o.o_orderkey IS NOT NULL
    )
WHERE 
    p.p_retailprice > (
        SELECT 
            AVG(p2.p_retailprice)
        FROM 
            part p2
        WHERE 
            p2.p_size IS NOT NULL
    )
    AND p.p_comment IS NOT NULL
GROUP BY 
    p.p_name, p.p_brand, ns.n_name
HAVING 
    COUNT(DISTINCT ps.ps_supkey) > 1
ORDER BY 
    total_available_quantity DESC, nation_name ASC
LIMIT 10;
