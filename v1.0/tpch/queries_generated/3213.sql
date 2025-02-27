WITH Ranked_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),

Customer_Orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

Nation_Stats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    n.n_name,
    ns.total_suppliers,
    ns.avg_supplier_acctbal,
    COALESCE(SUM(co.order_count), 0) AS total_orders,
    COALESCE(SUM(co.total_spent), 0) AS total_revenue
FROM 
    nation_stats ns
JOIN 
    nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN 
    Customer_Orders co ON n.n_nationkey = co.c_custkey
OUTER APPLY (
    SELECT 
        COUNT(DISTINCT ps.ps_partkey) AS supplier_parts
    FROM 
        partsupp ps
    JOIN 
        Ranked_Suppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rn <= 5
) AS sup_part
GROUP BY 
    n.n_name, ns.total_suppliers, ns.avg_supplier_acctbal
HAVING 
    SUM(co.total_spent) > 10000 OR COUNT(co.c_custkey) > 5
ORDER BY 
    total_revenue DESC;
