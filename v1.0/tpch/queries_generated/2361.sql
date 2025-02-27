WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        PERCENT_RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    si.s_name,
    si.total_supply_cost,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierInfo si ON rp.p_partkey = (SELECT ps.ps_partkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_suppkey = si.s_suppkey 
                                         ORDER BY ps.ps_supplycost ASC 
                                         LIMIT 1)
JOIN 
    CustomerOrders co ON co.total_spent > (SELECT AVG(co2.total_spent) 
                                            FROM CustomerOrders co2)
WHERE 
    rp.price_rank <= 0.2
ORDER BY 
    rp.p_retailprice DESC NULLS LAST,
    co.total_spent DESC;
