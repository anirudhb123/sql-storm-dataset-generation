WITH CTE_Customer_Supplier AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
CTE_Supplier_Stats AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.s_suppkey
),
National_Summary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    ss.total_supply_cost,
    ss.avg_avail_qty,
    ns.customer_count,
    ns.supplier_count
FROM 
    CTE_Customer_Supplier cs
LEFT JOIN 
    CTE_Supplier_Stats ss ON cs.c_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        WHERE 
            n.n_name = (SELECT n_name FROM nation WHERE n_nationkey = cs.c_nationkey)
    )
LEFT JOIN 
    National_Summary ns ON cs.c_nationkey = ns.customer_count
WHERE 
    cs.total_spent > (
        SELECT 
            AVG(total_spent) 
        FROM 
            CTE_Customer_Supplier
    )
AND 
    cs.order_count > 5
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
