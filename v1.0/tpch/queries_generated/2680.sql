WITH SupplierPartCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
Ranking AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        total_revenue,
        customer_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary o
)
SELECT 
    r.r_name,
    r.r_comment,
    n.n_name,
    n.n_comment,
    SUM(SPC.total_cost) AS total_supplier_part_cost,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    AVG(CASE WHEN os.total_revenue IS NOT NULL THEN os.total_revenue ELSE 0 END) AS avg_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierPartCosts SPC ON SPC.s_suppkey IN (SELECT s.n_nationkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
LEFT JOIN 
    Ranking os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE os.o_orderdate = o.o_orderdate)
GROUP BY 
    r.r_name,
    r.r_comment,
    n.n_name,
    n.n_comment
HAVING 
    SUM(SPC.total_cost) > 10000
ORDER BY 
    avg_revenue DESC;
