WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_totalprice IS NOT NULL
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp AS ps
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000.00
)
SELECT 
    p.p_name,
    p.p_mfgr,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS latest_order_date,
    RANK() OVER (ORDER BY AVG(o.o_totalprice) DESC) AS price_rank,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations
FROM 
    part AS p
LEFT JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    HighValueOrders AS o ON o.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE rn = 1)
LEFT JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND (p.p_retailprice - COALESCE((SELECT MAX(p2.p_retailprice) FROM part AS p2 WHERE p2.p_type = p.p_type), 0)) > 5.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
    AND MAX(o.o_orderdate) >= '2023-06-01'
ORDER BY 
    price_rank, supplier_name DESC;
