WITH CTE_SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS completed_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CTE_LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS average_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
CTE_RegionStats AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        AVG(c.c_acctbal) AS avg_customer_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
)

SELECT 
    r.r_name,
    ss.s_name,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ls.total_quantity,
    ls.average_discount,
    CASE 
        WHEN cs.total_spent IS NULL OR cs.total_spent > 1000 THEN 'HIGH SPENDER' 
        ELSE 'LOW SPENDER' 
    END AS spending_category,
    COALESCE(ss.total_supplycost / NULLIF(ss.unique_parts, 0), 0) AS avg_supply_cost_per_part
FROM 
    CTE_RegionStats r
JOIN 
    CTE_SupplierStats ss ON ss.unique_parts > 1
JOIN 
    CTE_CustomerOrders cs ON cs.total_orders > 5
LEFT JOIN 
    CTE_LineItemAnalysis ls ON cs.c_custkey = ls.l_orderkey
WHERE 
    r.avg_customer_balance IS NOT NULL
ORDER BY 
    r.r_name, ss.s_name;
