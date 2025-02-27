WITH CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(p.ps_supplycost * p.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TotalPerformance AS (
    SELECT 
        cs.c_name,
        cs.orders_count,
        cs.total_spent,
        ss.s_name AS supplier_name,
        ss.total_supplycost,
        (cs.total_spent - COALESCE(ss.total_supplycost, 0)) AS net_spending
    FROM 
        CustomerStats cs
    LEFT JOIN SupplierStats ss ON cs.orders_count > 5
)
SELECT 
    t.c_name,
    t.orders_count,
    t.total_spent,
    t.supplier_name,
    t.total_supplycost,
    t.net_spending,
    RANK() OVER (ORDER BY t.net_spending DESC) AS spending_rank
FROM 
    TotalPerformance t
WHERE 
    t.net_spending > 0
UNION ALL
SELECT 
    'No Suppliers' AS c_name,
    0 AS orders_count,
    0 AS total_spent,
    NULL AS supplier_name,
    NULL AS total_supplycost,
    0 AS net_spending
WHERE NOT EXISTS (SELECT 1 FROM SupplierStats)
ORDER BY spending_rank;
