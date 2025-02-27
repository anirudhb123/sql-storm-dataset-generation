WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
CustomerStatus AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        CASE 
            WHEN SUM(o.o_totalprice) > 10000 THEN 'High Value'
            WHEN SUM(o.o_totalprice) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS cust_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ns.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(tli.total_revenue) AS total_revenue,
    AVG(rs.s_acctbal) AS avg_supplier_acctbal
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerStatus c ON c.c_mktsegment = p.p_type
LEFT JOIN 
    TotalLineItems tli ON c.c_custkey = (
        SELECT MIN(l.o_custkey)
        FROM orders l
        WHERE l.o_orderkey = tli.l_orderkey
    )
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rn = 1
WHERE 
    c.cust_value = 'High Value'
    AND ns.r_name IS NOT NULL
GROUP BY 
    ns.n_name
HAVING 
    SUM(tli.total_revenue) > 50000
ORDER BY 
    total_revenue DESC;
