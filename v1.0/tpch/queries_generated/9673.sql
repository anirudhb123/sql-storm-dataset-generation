WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(cs.total_spent) AS total_spent,
    AVG(cs.order_count) AS avg_orders_per_customer,
    MAX(ro.total_revenue) AS highest_revenue_order,
    MAX(ts.total_supply_cost) AS highest_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    RankedOrders ro ON cs.c_custkey = ro.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON ts.ps_suppkey = cs.c_custkey
WHERE 
    r.r_name IN ('AMERICA', 'EUROPE')
GROUP BY 
    r.r_name
ORDER BY 
    total_spent DESC;
