WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(COALESCE(os.net_revenue, 0)) AS total_revenue,
    SUM(COALESCE(s.total_supply_cost, 0)) AS total_supply_cost,
    AVG(pr.part_revenue) AS avg_part_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    PartRevenue pr ON pr.p_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = c.c_custkey)
WHERE 
    s.s_acctbal > 10000
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
