WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE 
           WHEN o.o_orderstatus = 'F' THEN 
               l.l_extendedprice * (1 - l.l_discount)
           ELSE 
               0 
       END) AS total_freight_cost,
    MAX(p.p_retailprice) AS highest_price,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE s.s_acctbal > 1000) AS high_balance_suppliers,
    STRING_AGG(DISTINCT p.p_brand) AS distinct_brands
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RecursiveCTE rcte ON rcte.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierCTE scte ON scte.s_suppkey = l.l_suppkey
WHERE 
    rcte.rn <= 3
    AND (c.c_acctbal IS NULL OR c.c_acctbal > 100) 
    AND n.n_name IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0 
ORDER BY 
    customer_count DESC, total_freight_cost ASC;
