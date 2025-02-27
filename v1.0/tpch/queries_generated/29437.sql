WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_size,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type, p.p_size, p.p_brand, p.p_retailprice, p.p_comment
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ps.p_brand, 
    SUM(COALESCE(co.total_orders, 0)) AS total_orders_by_brand,
    SUM(COALESCE(co.total_spent, 0)) AS total_revenue_by_brand,
    AVG(ps.avg_supplycost) AS avg_supplier_cost_per_part,
    SUM(sp.total_cost) AS total_supplier_expense,
    COUNT(DISTINCT sp.s_suppkey) AS unique_suppliers
FROM 
    PartStats ps
LEFT JOIN 
    CustomerOrders co ON ps.p_brand = co.c_name
LEFT JOIN 
    SupplierPerformance sp ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sp.s_suppkey)
GROUP BY 
    ps.p_brand
ORDER BY 
    total_revenue_by_brand DESC;
