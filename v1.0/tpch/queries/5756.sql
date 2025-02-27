
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), SupplierNation AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        n.n_regionkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
), CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    RN.p_partkey, 
    RN.p_name,
    RN.p_brand,
    SN.nation_name, 
    CS.order_count,
    CS.total_spent,
    RN.total_supply_cost
FROM 
    RankedParts RN
JOIN 
    SupplierNation SN ON RN.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost * ps.ps_availqty = RN.total_supply_cost ORDER BY ps.ps_supplycost * ps.ps_availqty LIMIT 1)
JOIN 
    CustomerSummary CS ON CS.order_count > 5
WHERE 
    CS.total_spent > 1000
ORDER BY 
    RN.total_supply_cost DESC, 
    CS.order_count DESC;
