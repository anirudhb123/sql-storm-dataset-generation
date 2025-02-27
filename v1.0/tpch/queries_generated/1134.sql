WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartPricing AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary c
    WHERE 
        total_spent > 1000
)

SELECT 
    tc.c_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_retailprice,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN total_revenue > 10000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    TopCustomers tc
LEFT JOIN 
    orders o ON tc.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
JOIN 
    partsupp ps ON lp.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    SupplierPartPricing sp ON s.s_suppkey = sp.s_suppkey AND p.p_partkey = sp.ps_partkey
WHERE 
    lp.l_shipdate > '2023-01-01' AND 
    (lp.l_returnflag IS NULL OR lp.l_returnflag <> 'R')
GROUP BY 
    tc.c_name, s.s_name, p.p_name, p.p_retailprice
HAVING 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 5000
ORDER BY 
    total_revenue DESC;
