WITH CTE_Supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
CTE_Customer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
CTE_LineItem AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, 
        l.l_partkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(cs.total_supply_cost) AS avg_supply_cost,
    MAX( CASE 
             WHEN li.net_revenue IS NULL THEN 0 
             ELSE li.net_revenue 
         END ) AS max_net_revenue,
    SUM(CASE WHEN li.net_revenue > 1000 THEN 1 ELSE 0 END) AS high_revenue_count
FROM 
    nation n
LEFT JOIN 
    CTE_Customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CTE_Supplier cs ON cs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT DISTINCT li.l_partkey 
            FROM CTE_LineItem li
            WHERE li.net_revenue IS NOT NULL
        )
    )
LEFT JOIN 
    CTE_LineItem li ON li.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderdate >= DATEADD(month, -6, GETDATE())
    )
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_customers DESC, 
    avg_supply_cost ASC;
