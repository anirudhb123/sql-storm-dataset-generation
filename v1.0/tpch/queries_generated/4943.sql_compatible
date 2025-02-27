
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSegmentation AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ra.total_avail_qty,
    ra.total_supply_cost,
    cs.total_orders,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS retail_rank,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        ELSE cs.c_mktsegment 
    END AS customer_segment
FROM 
    part p
LEFT JOIN 
    SupplierAvailability ra ON p.p_partkey = ra.ps_partkey
LEFT JOIN 
    CustomerSegmentation cs ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = cs.c_custkey)
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)
    AND (ra.total_avail_qty IS NOT NULL OR cs.total_orders > 0)
    AND EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = p.p_partkey)
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    ra.total_avail_qty, 
    ra.total_supply_cost, 
    cs.total_orders, 
    cs.c_mktsegment
ORDER BY 
    p.p_name, retail_rank;
