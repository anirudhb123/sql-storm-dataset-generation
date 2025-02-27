WITH SupplierAverageCost AS (
    SELECT 
        ps.s_suppkey, 
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        supplier s
    JOIN 
        SupplierAverageCost sac ON s.s_suppkey = sac.s_suppkey
    WHERE 
        sac.avg_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    c.c_name, 
    co.order_count, 
    co.total_spent, 
    SUM(l.total_revenue) AS total_revenue_generated,
    hs.s_name AS high_value_supplier
FROM 
    CustomerOrderSummary co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    LineItemDetails l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem li ON ps.ps_partkey = li.l_partkey WHERE li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
GROUP BY 
    c.c_name, co.order_count, co.total_spent, hs.s_name
ORDER BY 
    total_revenue_generated DESC NULLS LAST;
