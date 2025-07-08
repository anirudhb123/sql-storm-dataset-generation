
WITH OrderCTE AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_shippriority, 
        o.o_comment,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
    UNION ALL 
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_shippriority, 
        o.o_comment,
        rn + 1
    FROM 
        orders o
    JOIN OrderCTE cte ON o.o_orderkey = cte.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' OR 
        o.o_orderstatus IS NULL
),
PartBrandASize AS (
    SELECT 
        p.p_brand,
        p.p_size,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size IS NOT NULL) OR 
        p.p_brand IS NULL
    GROUP BY 
        p.p_brand, 
        p.p_size
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_total,
    MAX(q.total_supply_cost) AS max_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    OrderCTE o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartBrandASize q ON q.p_brand IS NOT NULL
WHERE 
    (o.o_orderstatus IN ('F', 'O') OR 
     o.o_orderstatus IS NULL) AND 
    r.r_name LIKE '%East%' AND 
    (s.s_acctbal > 1000 OR 
     s.s_acctbal IS NULL)
GROUP BY 
    r.r_name, 
    o.o_orderkey, 
    o.o_orderstatus, 
    o.o_totalprice, 
    o.o_orderdate, 
    o.o_shippriority, 
    o.o_comment, 
    q.p_brand, 
    q.p_size
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 3 
    OR COALESCE(SUM(l.l_quantity), 0) > 500
ORDER BY 
    avg_order_total DESC, 
    total_revenue DESC
LIMIT 10;
