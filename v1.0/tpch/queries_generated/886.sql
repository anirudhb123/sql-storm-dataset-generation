WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
),
PartSupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) as total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) as total_orders,
        SUM(o.o_totalprice) as total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(pa.total_avail_qty, 0) as available_quantity,
    cs.total_orders,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent >= 1000 THEN 'Gold'
        WHEN cs.total_spent < 1000 AND cs.total_spent >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END as customer_segment,
    ROW_NUMBER() OVER (PARTITION BY cs.total_orders ORDER BY p.p_retailprice DESC) as price_rank
FROM 
    part p
LEFT JOIN 
    PartSupplierAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')))
WHERE 
    p.p_retailprice > 50 AND (cs.total_orders IS NULL OR cs.total_orders > 5)
ORDER BY 
    available_quantity DESC, 
    p.p_name;
