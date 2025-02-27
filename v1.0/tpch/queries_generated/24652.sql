WITH RankedSuppliers AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ROW_NUMBER() OVER(PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rn,
        SUM(ps_availqty) OVER(PARTITION BY ps_partkey) AS total_availqty
    FROM 
        partsupp
),
HighValueOrders AS (
    SELECT 
        o_orderkey, 
        o_totalprice, 
        o_orderdate,
        DENSE_RANK() OVER(ORDER BY o_totalprice DESC) AS price_rank
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O' AND 
        o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
),
SuspiciousSuppliers AS (
    SELECT 
        s_suppkey, s_name, s_acctbal
    FROM 
        supplier 
    WHERE 
        s_acctbal IS NULL OR s_acctbal < 0
),
CombinedData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        n.n_name AS nation_name,
        CASE 
            WHEN COUNT(DISTINCT l.l_orderkey) = 0 THEN 'No Lines'
            ELSE 'Lines Exist'
        END AS line_status
    FROM 
        lineitem l
    INNER JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        o.o_orderkey, n.n_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    AVG(total_availqty) AS avg_availqty,
    SUM(h.o_totalprice) AS total_high_value_order,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    cd.total_revenue,
    cd.line_status
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.rn = 1 
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = 
        (SELECT o_orderkey 
         FROM orders 
         WHERE o_totalprice = h.o_totalprice AND o_orderdate < '2023-01-01' 
         LIMIT 1)
LEFT JOIN 
    SuspiciousSuppliers s ON rs.ps_suppkey = s.s_suppkey
JOIN 
    CombinedData cd ON cd.line_status = 'Lines Exist'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name, cd.total_revenue, cd.line_status
HAVING 
    COUNT(DISTINCT h.o_orderkey) > 5 
ORDER BY 
    avg_availqty DESC, total_high_value_order DESC;
