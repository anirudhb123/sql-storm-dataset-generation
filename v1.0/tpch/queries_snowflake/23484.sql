
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        COUNT(DISTINCT l.l_partkey) AS items_ordered
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        n.n_regionkey,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
RevenueRanking AS (
    SELECT 
        od.o_orderkey, 
        od.o_custkey,
        od.total_revenue,
        RANK() OVER (PARTITION BY od.o_custkey ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
)

SELECT 
    cr.region_name,
    ss.s_name,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COALESCE(MAX(ss.total_cost), 0) AS supplier_cost,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    LISTAGG(DISTINCT cr.c_name, ', ') WITHIN GROUP (ORDER BY cr.c_name) AS customer_names
FROM 
    SupplierSummary ss
LEFT JOIN 
    lineitem l ON ss.s_suppkey = l.l_suppkey
LEFT JOIN 
    RevenueRanking od ON l.l_orderkey = od.o_orderkey
JOIN 
    CustomerRegion cr ON od.o_custkey = cr.c_custkey
WHERE 
    ss.total_cost >= ANY (SELECT DISTINCT AVG(total_cost) FROM SupplierSummary) 
    AND cr.n_regionkey IS NOT NULL
GROUP BY 
    cr.region_name, ss.s_name
HAVING 
    COUNT(DISTINCT cr.c_custkey) > 5
ORDER BY 
    total_revenue DESC, supplier_cost ASC
LIMIT 10;
