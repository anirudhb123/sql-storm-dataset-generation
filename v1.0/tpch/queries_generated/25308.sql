WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COUNT(DISTINCT ps.s_suppkey) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
HighValueParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand, 
        rp.total_supply_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5 AND rp.rank <= 10
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        COUNT(o.o_orderkey) > 10
)
SELECT 
    hvp.p_partkey,
    hvp.p_name,
    hvp.p_brand,
    fc.c_custkey,
    fc.c_name,
    fc.order_count,
    hvp.total_supply_cost
FROM 
    HighValueParts hvp
JOIN 
    FrequentCustomers fc ON fc.c_acctbal > hvp.total_supply_cost / 10
ORDER BY 
    hvp.total_supply_cost DESC, 
    fc.order_count DESC;
