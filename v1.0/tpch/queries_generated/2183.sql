WITH Customer_Order_Summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Supplier_Part_Summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Order_Lineitem_Stats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    co.c_custkey, 
    co.c_name, 
    co.total_spent, 
    sp.parts_supplied, 
    sp.total_supply_cost,
    ol.net_revenue,
    ol.avg_quantity,
    CASE 
        WHEN ol.revenue_rank = 1 THEN 'Top Revenue'
        ELSE 'Other Revenue'
    END AS revenue_category
FROM 
    Customer_Order_Summary co
LEFT JOIN 
    Supplier_Part_Summary sp ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1) LIMIT 1) -- assuming a mapping to suppliers
LEFT JOIN 
    Order_Lineitem_Stats ol ON ol.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE 
    co.total_spent IS NOT NULL AND 
    sp.total_supply_cost > 1000
ORDER BY 
    co.total_spent DESC, 
    sp.parts_supplied ASC;
