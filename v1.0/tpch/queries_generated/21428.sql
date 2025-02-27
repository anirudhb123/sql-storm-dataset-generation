WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
), 
FrequentOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
    HAVING 
        COUNT(o.o_orderkey) > 3
), 
ExceedingDiscounts AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_discount) AS total_discount
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' AND l.l_discount > 0.1
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_discount) > 1.0
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    eo.total_discount,
    fo.order_count,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    FrequentOrders fo ON fo.o_custkey = l.l_suppkey
LEFT JOIN 
    ExceedingDiscounts eo ON eo.l_orderkey = l.l_orderkey
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = fo.o_custkey)
WHERE 
    p.p_size IS NOT NULL
    AND (l.l_shipdate < CURRENT_DATE OR l.l_receiptdate IS NULL)
    AND (n.n_name LIKE '%land%' OR n.n_name NOT LIKE '%land%' AND n.n_comment IS NULL)
GROUP BY 
    n.n_name, p.p_name, rs.s_name, eo.total_discount, fo.order_count
ORDER BY 
    total_cost DESC, supplier_name DESC NULLS LAST
LIMIT 100;
