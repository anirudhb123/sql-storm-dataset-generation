WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_price,
        CTE.naming_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    CROSS JOIN (
        SELECT 
            c.c_custkey, 
            ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS naming_rank
        FROM 
            customer c
        WHERE 
            c.c_acctbal IS NOT NULL
    ) AS CTE ON o.o_custkey = CTE.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, CTE.naming_rank
),
MaxTotalPrice AS (
    SELECT 
        MAX(o_totalprice) AS max_price
    FROM 
        CustomerOrders
)
SELECT 
    p.p_name,
    r.r_name,
    COALESCE(MAX(total_line_item_price), 0) AS max_total_line_item_price,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    CASE 
        WHEN s.s_acctbal IS NOT NULL THEN 'Valid Supplier' 
        ELSE 'Unknown Supplier' 
    END AS supplier_status,
    MAX(o.o_orderstatus) OVER () AS global_order_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN 
    CustomerOrders o ON p.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COALESCE(MAX(total_line_item_price), 0) > (SELECT COALESCE(max_price, 0) FROM MaxTotalPrice) OR COUNT(DISTINCT s.s_suppkey) = 0
ORDER BY 
    p.p_name ASC, r.r_name DESC;
