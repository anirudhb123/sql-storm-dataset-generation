WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.total_revenue) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(od.total_revenue) > 10000
),
SupplierPerformance AS (
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        ROUND(SUM(od.total_revenue) / NULLIF(SUM(sc.total_supply_cost), 0), 2) AS performance_ratio
    FROM 
        SupplierCosts sc
    LEFT JOIN 
        lineitem l ON sc.s_suppkey = l.l_suppkey
    LEFT JOIN 
        OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY 
        sc.s_suppkey, sc.s_name
)
SELECT 
    h.c_custkey,
    h.c_name,
    s.s_suppkey,
    s.s_name,
    s.performance_ratio
FROM 
    HighValueCustomers h
JOIN 
    SupplierPerformance s ON h.total_revenue > 50000
ORDER BY 
    s.performance_ratio DESC, h.c_name ASC;
