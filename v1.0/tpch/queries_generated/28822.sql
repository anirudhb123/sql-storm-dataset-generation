WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
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
    GROUP BY 
        c.c_custkey
),
FinalReport AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.supplier_count,
        rp.total_supply_cost,
        co.order_count,
        co.total_spent
    FROM 
        RankedParts rp
    LEFT JOIN 
        CustomerOrders co ON rp.rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.supplier_count,
    p.total_supply_cost,
    COALESCE(c.order_count, 0) AS order_count,
    COALESCE(c.total_spent, 0) AS total_spent
FROM 
    FinalReport p
LEFT JOIN 
    CustomerOrders c ON p.p_partkey = c.c_custkey
ORDER BY 
    p.total_supply_cost DESC, 
    p.supplier_count DESC;
