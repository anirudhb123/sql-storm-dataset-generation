WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000 -- Starting point for suppliers with a high account balance
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey -- Simulating hierarchy through self-join
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(t.total_revenue) AS max_order_revenue,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    CASE 
        WHEN d.rn IS NOT NULL THEN 'Customer Segment Qualifier'
        ELSE 'Other'
    END AS segment_status,
    CAST('Supplier Level: ' AS VARCHAR(50)) || sh.level AS supplier_level
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerSegment d ON s.s_nationkey = d.c_nationkey
LEFT JOIN 
    ActiveOrders t ON p.p_partkey = t.o_orderkey -- Using part key as a reference for active orders
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 200.00)
AND 
    (p.p_comment IS NULL OR p.p_comment LIKE '%premium%')
GROUP BY 
    p.p_partkey, p.p_name, n.n_name, d.rn, sh.level
ORDER BY 
    total_available_quantity DESC, max_order_revenue DESC;
