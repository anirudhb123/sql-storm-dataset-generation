WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    UNION ALL
    SELECT 
        s2.s_suppkey, 
        s2.s_name, 
        s2.s_nationkey, 
        s2.s_acctbal, 
        sh.level + 1
    FROM 
        supplier s2
    JOIN 
        SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE 
        s2.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_orderkey) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        CASE 
            WHEN SUM(o.o_totalprice) IS NULL THEN 0 
            ELSE SUM(o.o_totalprice) 
        END AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_mfgr,
    ph.p_brand,
    ph.p_type,
    SUM(ps.ps_availqty) AS total_available,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    COALESCE(rs.total_value, 0) AS total_retail_value,
    STRING_AGG(CASE WHEN cs.orders_count > 0 THEN cs.c_name ELSE 'No Orders' END, ', ') AS customer_names
FROM 
    part ph
LEFT JOIN 
    partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    OrderSummary rs ON o.o_orderkey = rs.o_orderkey
LEFT JOIN 
    CustomerStats cs ON o.o_custkey = cs.c_custkey
GROUP BY 
    ph.p_partkey, ph.p_name, ph.p_mfgr, ph.p_brand, ph.p_type
HAVING 
    SUM(ps.ps_availqty) > 10
ORDER BY 
    total_available DESC, total_retail_value DESC;
