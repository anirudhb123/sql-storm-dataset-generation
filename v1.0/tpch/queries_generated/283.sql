WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierPartCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(MAX(s.s_name), 'No Supplier') AS supplier_name,
        MAX(ps.ps_availqty) AS available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    cos.c_name,
    cos.total_spent,
    cos.total_orders,
    cos.last_order_date,
    ps.p_name,
    ps.available_quantity,
    ps.supplier_name,
    la.net_revenue,
    la.avg_quantity
FROM 
    CustomerOrderSummary cos
JOIN 
    PartSupplierDetails ps ON ps.available_quantity > 0
JOIN 
    LineItemAnalysis la ON la.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cos.c_custkey)
ORDER BY 
    cos.total_spent DESC,
    la.net_revenue DESC
FETCH FIRST 10 ROWS ONLY;
