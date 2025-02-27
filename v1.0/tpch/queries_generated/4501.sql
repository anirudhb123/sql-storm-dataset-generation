WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name AS customer_name,
    cs.order_count,
    cs.total_spent,
    ps.total_sales AS part_sales,
    ss.s_name AS top_supplier,
    ss.total_supply_cost,
    ss.unique_parts_supplied
FROM 
    CustomerOrders cs
LEFT JOIN 
    PartSales ps ON cs.order_count > 0
LEFT JOIN 
    SupplierStats ss ON ps.order_count > 0
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
  AND 
    (ss.total_supply_cost IS NOT NULL OR ss.s_name IS NULL)
ORDER BY 
    cs.total_spent DESC, ss.total_supply_cost DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
