WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
), 
CustomerSupplier AS (
    SELECT 
        c.c_custkey,
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        customer c
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        c.c_custkey, s.s_suppkey
)
SELECT 
    p.p_name,
    r.r_name AS region_name,
    coalesce(SUM(l.l_discount), 0) AS total_discount,
    MAX(o.o_orderdate) AS last_order_date,
    CASE 
        WHEN COUNT(DISTINCT cs.c_custkey) > 10 THEN 'High'
        WHEN COUNT(DISTINCT cs.c_custkey) BETWEEN 1 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_engagement_level
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerSupplier cs ON cs.s_suppkey = s.s_suppkey
WHERE 
    p.p_size > 20 AND 
    (r.r_name LIKE '%East%' OR r.r_name IS NULL)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    CASE WHEN SUM(l.l_tax) IS NULL THEN AVG(l.l_extendedprice) < 0 
    ELSE SUM(l.l_tax) < 100 
    END
ORDER BY 
    region_name ASC, total_discount DESC
LIMIT 100;
