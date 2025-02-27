WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_container,
        RANK() OVER (PARTITION BY p.p_container ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS national_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    WHERE 
        r.r_comment LIKE '%important%'
    GROUP BY 
        r.r_regionkey, r.r_name
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '1 year')
)
SELECT 
    c.c_name, 
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_spent,
    rp.p_name AS top_part_name,
    rg.r_name AS region_name,
    fo.o_orderdate
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.price_rank = 1
JOIN 
    TopRegions rg ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rg.r_regionkey)
JOIN 
    FilteredOrders fo ON o.o_orderkey = fo.o_orderkey
WHERE 
    c.c_acctbal IS NOT NULL AND c.c_acctbal > (
        SELECT MAX(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_mktsegment IS NOT NULL AND c2.c_mktsegment <> ' ')
GROUP BY 
    c.c_name, rp.p_name, rg.r_name, fo.o_orderdate
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2)
ORDER BY 
    total_spent DESC, c.c_name
LIMIT 10;
