WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal <= 0 THEN 'Non-positive Balance' 
            ELSE 'Positive Balance' 
        END AS balance_status
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalLineItem AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        l.l_orderkey
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COALESCE(t.total_price, 0) AS total_price
    FROM 
        orders o
    LEFT JOIN 
        TotalLineItem t ON o.o_orderkey = t.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT qs.o_orderkey) AS order_count,
    SUM(CASE 
            WHEN qs.total_price > 0 THEN 1 ELSE 0 
        END) AS positive_total_count,
    AVG(CASE 
            WHEN qs.total_price = 0 THEN NULL ELSE qs.total_price 
        END) AS avg_positive_total,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_acctbal, ' (', balance_status, ')'), '; ') AS supplier_info
FROM 
    RankedSuppliers s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    QualifiedOrders qs ON ps.ps_partkey IN (
        SELECT DISTINCT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = qs.o_orderkey
    )
WHERE 
    p.p_size >= 10 AND 
    p.p_retailprice BETWEEN 50.00 AND 200.00
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT qs.o_orderkey) > 5
ORDER BY 
    r.r_name;
