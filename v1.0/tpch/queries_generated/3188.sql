WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    n.customer_count,
    n.total_orders,
    n.total_revenue,
    COALESCE(ss.total_available, 0) AS supplier_availability,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supplier_cost,
    YEAR(o.o_orderdate) AS order_year
FROM 
    NationSummary n
LEFT JOIN 
    SupplierStats ss ON n.n_name = (SELECT n2.n_name 
                                      FROM nation n2 
                                      WHERE n2.n_nationkey = (SELECT c.c_nationkey 
                                                               FROM customer c 
                                                               WHERE c.c_custkey = (SELECT o2.o_custkey 
                                                                                   FROM orders o2 
                                                                                   WHERE o2.o_orderkey = o.o_orderkey)))
)
JOIN 
    RankedOrders o ON o.o_orderkey IN (SELECT o2.o_orderkey FROM RankedOrders o2 WHERE o2.rn = 1)
WHERE 
    n.total_revenue IS NOT NULL
ORDER BY 
    n.customer_count DESC, 
    n.total_revenue DESC;
