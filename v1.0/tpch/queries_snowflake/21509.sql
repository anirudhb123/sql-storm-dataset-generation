WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > 1000.00
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice
),
HighValueNation AS (
    SELECT 
        n.n_nationkey,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        SUM(s.s_acctbal) > 50000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(rn.s_name, 'No Supplier') AS supplier_name,
    ao.o_totalprice AS order_total,
    ao.line_count AS total_line_items,
    CASE 
        WHEN ao.o_orderstatus IS NULL THEN 'No Active Order'
        ELSE 'Active Order Exists'
    END AS order_status_info
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    rankedSuppliers rn ON ps.ps_suppkey = rn.s_suppkey AND rn.rank = 1
LEFT JOIN 
    ActiveOrders ao ON ao.o_orderkey = (
        SELECT 
            MAX(o_orderkey) 
        FROM 
            ActiveOrders
        WHERE 
            o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM HighValueNation n))
    )
WHERE 
    (p.p_size IS NULL OR p.p_size >= 10) 
    AND (p.p_comment LIKE '%urgent%' OR p.p_container = 'BOX')
ORDER BY 
    p.p_partkey DESC, 
    order_total DESC NULLS LAST;
