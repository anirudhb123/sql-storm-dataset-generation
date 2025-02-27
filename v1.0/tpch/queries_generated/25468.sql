WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
        )
), 
PartSuppliers AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        rp.rn <= 5
    GROUP BY 
        rp.p_partkey, rp.p_name, s.s_name
), 
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name
)
SELECT 
    ps.p_name,
    ps.s_name,
    ps.total_supply_cost,
    co.total_order_value,
    co.order_count
FROM 
    PartSuppliers ps
JOIN 
    CustomerOrders co ON ps.supplier_count = co.order_count
ORDER BY 
    ps.total_supply_cost DESC, co.total_order_value ASC
LIMIT 10;
