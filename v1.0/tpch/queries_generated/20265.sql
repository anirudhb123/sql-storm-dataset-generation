WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    MAX(r.o_orderdate) AS last_order_date,
    CONCAT(s.s_name, ' from ', s.s_address) AS supplier_info,
    (SELECT 
         COUNT(*) 
     FROM 
         customer c 
     WHERE 
         c.c_acctbal > 
            (SELECT AVG(c2.c_acctbal) 
             FROM customer c2 
             WHERE c2.c_nationkey = s.s_nationkey)) AS wealthy_customers_count
FROM 
    part p
JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey 
LEFT JOIN 
    RankedOrders r ON r.o_orderkey = li.l_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_brand = p.p_brand)
    AND (s.s_acctbal IS NULL OR s.s_acctbal < 1000)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
HAVING 
    SUM(li.l_quantity) > (SELECT COALESCE(SUM(li2.l_quantity), 0) 
                          FROM lineitem li2 
                          WHERE li2.l_returnflag = 'Y') / NULLIF(COUNT(li.l_orderkey), 0)
                          AND COUNT(DISTINCT r.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, order_count ASC;
