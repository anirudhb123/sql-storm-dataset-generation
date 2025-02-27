WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comments') AS supplier_comments
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 1000
          AND EXISTS (
              SELECT 1 
              FROM customer c 
              WHERE c.c_custkey = o.o_custkey 
                AND c.c_mktsegment = 'BUILDING'
          )
), 
LinesWithSupplier AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        s.s_name AS supplier_name,
        COALESCE(AVG(l.l_discount), 0.0) AS avg_discount
    FROM 
        lineitem l
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, s.s_name
)
SELECT 
    r.n_name AS nation_name,
    pp.p_name,
    SUM(CASE WHEN pp.price_rank = 1 THEN li.l_extendedprice ELSE 0 END) AS top_price_sum,
    COUNT(DISTINCT o.o_orderkey) AS high_value_orders_count,
    STRING_AGG(DISTINCT si.supplier_comments, '; ') AS distinct_supplier_comments
FROM 
    RankedParts pp
JOIN 
    LinesWithSupplier li ON pp.p_partkey = li.l_partkey
JOIN 
    HighValueOrders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation r ON c.c_nationkey = r.n_nationkey
JOIN 
    SupplierInfo si ON li.supplier_name = si.s_name
WHERE 
    pp.p_retailprice IS NOT NULL
    AND (li.avg_discount > 0.10 OR li.l_quantity > 50)
GROUP BY 
    r.n_name, pp.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    top_price_sum DESC, r.n_name ASC;
