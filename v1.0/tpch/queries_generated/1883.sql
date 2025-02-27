WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied,
        MAX(ps.ps_availqty) AS max_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY sp.total_supply_cost DESC) AS rank_supplier,
    sp.s_name AS supplier_name,
    sp.total_supply_cost,
    co.total_spent,
    pa.p_name AS part_name,
    pa.total_available_quantity,
    pa.avg_supply_cost
FROM 
    SupplierPerformance sp
FULL OUTER JOIN 
    CustomerOrders co ON sp.rank_by_cost <= 10 AND co.order_rank <= 10
LEFT JOIN 
    PartAvailability pa ON pa.avg_supply_cost IS NOT NULL
WHERE 
    co.total_orders IS NOT NULL
ORDER BY 
    sp.total_supply_cost DESC, co.total_spent DESC;
