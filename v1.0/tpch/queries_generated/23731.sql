WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        (SELECT COUNT(*) 
         FROM partsupp ps 
         WHERE ps.ps_suppkey = s.s_suppkey 
         GROUP BY ps.ps_suppkey HAVING SUM(ps.ps_supplycost) > 10000) AS high_costs
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o1.o_totalprice) FROM orders o1)
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p 
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT 
    pi.p_name,
    pi.p_brand,
    pi.p_retailprice,
    CASE 
        WHEN pi.total_quantity > 100 THEN 'High Supply'
        ELSE 'Low Supply'
    END AS supply_status,
    AVG(o.o_totalprice) AS avg_order_value,
    ns.n_name AS nation_name,
    CASE WHEN r.rank IS NOT NULL THEN 'Ranked' ELSE 'Unranked' END AS supplier_rank_status
FROM 
    PartInfo pi
LEFT JOIN 
    HighValueOrders o ON pi.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
LEFT JOIN 
    RankedSuppliers r ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pi.p_partkey AND r.rank = 1)
JOIN 
    nation ns ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IS NOT NULL LIMIT 1)
GROUP BY 
    pi.p_name, pi.p_brand, pi.p_retailprice, r.rank, ns.n_name
HAVING 
    (AVG(o.o_totalprice) IS NOT NULL OR COUNT(o.o_orderkey) > 0)
AND 
    ( pi.total_quantity IS NOT NULL AND pi.total_quantity > 0 )
ORDER BY 
    supply_status DESC, avg_order_value DESC;
