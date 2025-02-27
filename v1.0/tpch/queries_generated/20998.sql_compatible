
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
PartSupps AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        COALESCE(NULLIF(ps.ps_comment, ''), 'No Comment') AS sanitized_comment
    FROM 
        partsupp ps
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
        COUNT(l.l_linenumber) AS total_lines,
        l.l_partkey
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    co.c_name,
    rs.s_name AS top_supplier,
    l.total_extended_price,
    CASE 
        WHEN l.total_lines > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_volume_category,
    p.p_name,
    CASE 
        WHEN rs.rnk = 1 THEN 'Primary Supplier'
        ELSE 'Other Supplier'
    END AS supplier_type
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemDetails l ON co.o_orderkey = l.l_orderkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM PartSupps ps 
        WHERE ps.ps_partkey = l.l_partkey 
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
JOIN 
    part p ON p.p_partkey = l.l_partkey
WHERE 
    co.recent_order_rank = 1
    AND l.total_extended_price > (SELECT AVG(total_extended_price) FROM LineItemDetails)
ORDER BY 
    co.c_name, l.total_extended_price DESC;
