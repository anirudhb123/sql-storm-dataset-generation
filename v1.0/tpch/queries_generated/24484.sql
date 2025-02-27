WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate BETWEEN '2020-01-01' AND '2023-01-01')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
),
RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice, 
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,  
    COALESCE(SUM(l.l_extendedprice), 0) AS total_revenue,
    COUNT(DISTINCT CASE WHEN o.o_orderkey IS NULL THEN NULL ELSE o.o_orderkey END) AS order_count,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region'
        ELSE r.r_name
    END AS region_name
FROM 
    part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    (p.p_size BETWEEN 10 AND 50 OR p.p_comment LIKE '%special%')
    AND (p.p_retailprice IS NOT NULL OR ps.ps_supplycost IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, r.r_name
HAVING 
    SUM(l.l_quantity) >= ALL (SELECT AVG(l2.l_quantity) FROM lineitem l2 GROUP BY l2.l_orderkey HAVING COUNT(l2.l_linenumber) > 1)
    OR EXISTS (SELECT 1 FROM RecentLineItems rl WHERE rl.l_orderkey = o.o_orderkey)
ORDER BY 
    total_revenue DESC
LIMIT 10 OFFSET 5;
