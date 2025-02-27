WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 100 THEN 'High Price'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate Price'
            ELSE 'Low Price'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50 AND
        p.p_comment NOT LIKE '%defective%'
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_discount) AS max_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(CASE 
            WHEN o.o_orderstatus = 'F' THEN os.total_revenue 
            ELSE NULL 
        END) AS avg_fulfilled_revenue,
    SUM(CASE 
            WHEN hs.acct_rank = 1 THEN ps.ps_availqty 
            ELSE 0 
        END) AS total_available_qty
FROM 
    partsupp ps
JOIN 
    HighValueParts p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers hs ON ps.ps_suppkey = hs.s_suppkey AND hs.acct_rank <= 3
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN 
        (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = hs.s_nationkey))
WHERE 
    p.price_category = 'High Price'
GROUP BY 
    ps.ps_partkey, p.p_name
HAVING 
    SUM(ps.ps_availqty) > (SELECT AVG(ps_availqty) FROM partsupp) AND
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    total_available_qty DESC, avg_fulfilled_revenue DESC NULLS LAST;
