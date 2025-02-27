WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSpend AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name, 
    p.p_name, 
    ss.total_available_qty, 
    ss.avg_supply_cost, 
    cs.total_spent,
    COALESCE(cs.total_spent, 0) AS customer_spending, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey IN (SELECT o.o_orderkey FROM RankedOrders ro WHERE ro.order_rank <= 10)
LEFT JOIN 
    CustomerSpend cs ON cs.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey = s.s_suppkey
GROUP BY 
    r.r_name, p.p_name, ss.total_available_qty, ss.avg_supply_cost, cs.total_spent
HAVING 
    SUM(ps.ps_availqty) > 100 AND COALESCE(cs.total_spent, 0) > 0
ORDER BY 
    r.r_name, p.p_name;
