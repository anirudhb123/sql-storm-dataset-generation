WITH ProductSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ps.p_name,
    ps.total_available,
    cs.c_name,
    cs.total_orders,
    sp.s_name,
    sp.num_parts_supplied,
    sp.total_supply_cost
FROM 
    ProductSummary ps
JOIN 
    CustomerOrderSummary cs ON ps.total_available > 0
JOIN 
    SupplierPerformance sp ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
ORDER BY 
    ps.total_available DESC, cs.total_spent DESC, sp.total_supply_cost DESC
LIMIT 100;
