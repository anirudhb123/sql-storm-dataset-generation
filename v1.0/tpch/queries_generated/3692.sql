WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_custkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 1000
)
SELECT 
    p.p_name,
    COUNT(DISTINCT lo.o_orderkey) AS order_count,
    SUM(lo.l_quantity) AS total_quantity,
    AVG(lo.l_extendedprice) AS avg_price,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COALESCE(MIN(rs.s_name), 'No Supplier') AS top_supplier,
    MAX(ho.o_totalprice) AS max_order_value
FROM 
    part p
LEFT JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON lo.l_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    HighValueOrders ho ON lo.l_orderkey = ho.o_orderkey
WHERE 
    p.p_type LIKE '%plastic%'
    AND (lo.l_shipdate IS NOT NULL OR lo.l_commitdate IS NULL)
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT lo.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
