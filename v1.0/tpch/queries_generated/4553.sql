WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_availability, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_returnflag = 'N'
        AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name,
    SUM(os.total_revenue) AS total_revenue,
    AVG(sp.total_cost) AS avg_supplier_cost,
    COUNT(DISTINCT os.o_custkey) AS unique_customers
FROM 
    OrderSummary os
JOIN 
    customer c ON os.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT OUTER JOIN 
    SupplierPerformance sp ON n.n_nationkey = sp.s_nationkey 
WHERE 
    sp.supplier_rank = 1
GROUP BY 
    r.r_name
HAVING 
    SUM(os.total_revenue) > 1000000
ORDER BY 
    total_revenue DESC;
