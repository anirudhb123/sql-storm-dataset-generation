WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(COALESCE(ss.total_avail_qty, 0)) AS total_available_quantity,
    SUM(CASE WHEN rp.price_rank = 1 THEN rp.p_retailprice ELSE 0 END) AS highest_priced_parts, 
    AVG(cs.total_spent) AS average_spent_per_customer
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey 
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey 
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = s.s_suppkey 
LEFT JOIN 
    RankedParts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT cs.c_custkey) > 0 
ORDER BY 
    total_available_quantity DESC;
