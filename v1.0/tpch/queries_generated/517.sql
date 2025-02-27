WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ss.total_cost,
    ss.avg_balance,
    lis.revenue,
    lis.line_count,
    lis.rank_revenue
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierSummary ss ON ss.total_cost > 10000
LEFT JOIN 
    LineItemSummary lis ON cs.order_count > 5 AND cs.last_order_date > '2022-01-01'
WHERE 
    cs.total_spent IS NOT NULL
    AND (ss.avg_balance IS NULL OR ss.avg_balance < 5000)
ORDER BY 
    cs.total_spent DESC, lis.revenue ASC
LIMIT 10;
