WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        MAX(ps.ps_availqty) AS max_availqty,
        MIN(CASE WHEN ps.ps_comment LIKE '%urgent%' THEN ps.ps_supplycost ELSE NULL END) AS urgent_supplycost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    c.c_name,
    COALESCE(ss.part_count, 0) AS part_count,
    COALESCE(ss.total_supplycost, 0) AS total_supplycost,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        WHEN c.total_spent > 100000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type,
    CASE 
        WHEN so.revenue_rank IS NOT NULL AND so.revenue_rank <= 10 THEN 'Top Revenue Order'
        ELSE 'Other Order'
    END AS order_classification
FROM 
    RankedOrders AS so
JOIN 
    CustomerSpending AS c ON so.o_orderkey = c.c_custkey
LEFT JOIN 
    SupplierSummary AS ss ON c.c_custkey = ss.s_suppkey
WHERE 
    (so.total_revenue IS NOT NULL OR so.total_revenue > 0)
    AND (ss.total_supplycost IS NULL OR ss.total_supplycost BETWEEN 1000 AND 5000)
ORDER BY 
    so.total_revenue DESC;
