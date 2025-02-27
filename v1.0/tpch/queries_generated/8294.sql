WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name,
    ns.region_name,
    ss.s_name,
    cs.c_name,
    cs.total_order_value,
    ss.total_avail_qty,
    ss.total_supply_cost,
    ss.part_count
FROM 
    NationRegion ns
JOIN 
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand = 'Brand#44' AND ps.ps_availqty > 0
    )
JOIN 
    CustomerOrderTotals cs ON cs.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrderTotals)
WHERE 
    ns.n_nationkey IN (
        SELECT s.s_nationkey FROM supplier s WHERE s.s_acctbal > 100.00
    )
ORDER BY 
    ns.region_name, cs.total_order_value DESC;
