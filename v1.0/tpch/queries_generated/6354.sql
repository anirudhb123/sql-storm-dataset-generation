WITH RankedProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (10, 20, 30)
), 
SupplierRegions AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name, s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    rp.p_name, 
    rp.p_retailprice, 
    sr.nation_name, 
    sr.region_name, 
    co.total_spent
FROM 
    RankedProducts rp
JOIN 
    SupplierRegions sr ON sr.total_supply_cost > 10000
JOIN 
    CustomerOrders co ON co.total_spent > 5000
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_spent DESC;
