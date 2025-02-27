WITH RECURSIVE PartStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        COUNT(ps.ps_suppkey) OVER (PARTITION BY p.p_partkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
RegionNations AS (
    SELECT 
        r.r_name, 
        n.n_name, 
        n.n_regionkey
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    ps.p_partkey, 
    ps.p_name, 
    ps.supplier_count, 
    ps.total_avail_qty,
    rn.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_totalprice) AS max_order_price,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Purchases'
        ELSE 'Purchases Exist'
    END AS purchase_status,
    COALESCE(ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2), 0) AS avg_revenue
FROM 
    PartStats ps
LEFT JOIN 
    lineitem l ON ps.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueOrders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    RegionNations rn ON rn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey LIMIT 1)
GROUP BY 
    ps.p_partkey, ps.p_name, ps.supplier_count, ps.total_avail_qty, rn.r_name
HAVING 
    MAX(o.o_totalprice) < (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'F')
ORDER BY 
    purchase_status DESC, max_order_price DESC
LIMIT 100 OFFSET 10;
