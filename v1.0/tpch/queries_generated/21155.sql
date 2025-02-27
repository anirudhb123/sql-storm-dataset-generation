WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1994-01-01' AND '1996-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END AS adjusted_acctbal,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 1000
    GROUP BY 
        o.o_orderkey
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        COALESCE(c.c_mktsegment, 'Unknown') AS mkt_segment
    FROM 
        customer c
    WHERE 
        c.c_acctbal NOT BETWEEN 100 AND 500
)
SELECT 
    r.r_name,
    p.p_type,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(COALESCE(s.adjusted_acctbal, 0)) AS total_supplier_balance,
    AVG(CASE 
            WHEN h.total_value IS NOT NULL THEN h.total_value 
            ELSE 0 
        END) AS avg_order_value,
    STRING_AGG(DISTINCT cs.mkt_segment, ', ') AS market_segments
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    HighValueOrders h ON h.o_orderkey = ps.ps_partkey
JOIN 
    RankedOrders o ON o.o_orderkey = h.o_orderkey
JOIN 
    CustomerSegment cs ON cs.c_custkey = o.o_orderkey
WHERE 
    r.r_name LIKE 'N%' 
    OR (n.n_name IN (SELECT DISTINCT n2.n_name FROM nation n2 WHERE n2.n_comment IS NOT NULL))
GROUP BY 
    r.r_name, p.p_type
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
    AND SUM(ps.ps_supplycost) > 5000
ORDER BY 
    r.r_name, p.p_type;
