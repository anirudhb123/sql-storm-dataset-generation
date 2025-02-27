WITH RecursivePartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_costs
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    CASE 
        WHEN SUM(RP.total_sales) IS NULL THEN 0 
        ELSE SUM(RP.total_sales) 
    END AS total_part_sales,
    COALESCE(SUM(SS.supply_costs), 0) AS total_supply_costs,
    CS.total_orders,
    CS.avg_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSales SS ON s.s_suppkey = SS.s_suppkey
LEFT JOIN 
    RecursivePartSales RP ON s.s_suppkey = RP.p_partkey
LEFT JOIN 
    CustomerOrderSummary CS ON s.s_suppkey = CS.c_custkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, CS.total_orders, CS.avg_order_value
HAVING 
    total_part_sales > 100000
ORDER BY 
    total_part_sales DESC;
