WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size IN (5, 10, 15) AND 
        p.p_retailprice > 100.00
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_custkey
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey, 
        n.n_name AS nation, 
        COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name
)
SELECT 
    cp.c_custkey, 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_retailprice, 
    sr.supply_count, 
    co.order_count, 
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.order_count > 0
JOIN 
    SupplierRegion sr ON sr.supply_count > 5
WHERE 
    rp.supply_rank = 1
ORDER BY 
    co.total_spent DESC, 
    rp.p_retailprice ASC 
LIMIT 100;
