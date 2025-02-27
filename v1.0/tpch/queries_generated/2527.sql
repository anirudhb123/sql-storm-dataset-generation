WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierData AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_supply_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    psd.p_name AS part_name,
    psd.total_supply_qty,
    ss.s_name AS supplier_name,
    CASE 
        WHEN ss.total_avail_qty IS NULL THEN 'Not Available'
        ELSE 'Available'
    END AS availability_status,
    RANK() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS customer_rank
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    PartSupplierData psd ON psd.unique_suppliers > 0
LEFT JOIN 
    SupplierStats ss ON ss.rn = 1
WHERE 
    cs.total_orders > 0
    AND (cs.total_spent > 500 OR psd.total_supply_qty < 100)
ORDER BY 
    cs.total_spent DESC,
    psd.total_supply_qty ASC;
