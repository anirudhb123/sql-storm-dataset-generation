WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' 
        AND o.o_orderstatus IN ('O', 'P') 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value 
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name 
    FROM 
        CustomerOrders c
    WHERE 
        c.order_count > 5 AND c.avg_order_value > 1000
)
SELECT 
    r.r_name,
    COALESCE(sp.total_available, 0) AS supplier_total_available,
    COALESCE(sp.total_cost, 0) AS supplier_total_cost,
    co.order_count AS high_value_order_count,
    co.avg_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN 
    HighValueCustomers co ON s.s_suppkey = co.c_custkey
WHERE 
    r.r_name LIKE '%North%' OR co.order_count IS NOT NULL
ORDER BY 
    r.r_name, supplier_total_available DESC;
