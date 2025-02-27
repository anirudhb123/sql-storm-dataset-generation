WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    nc.n_name,
    COALESCE(ss.total_parts, 0) AS total_supplies,
    COALESCE(ts.total_spent, 0) AS total_customer_spending,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(ro.net_revenue) AS avg_order_value
FROM 
    nation nc
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_brand = 'BrandX')
LEFT JOIN 
    TopCustomers ts ON nc.n_nationkey = (SELECT customer.n_nationkey FROM customer WHERE customer.c_custkey = ts.c_custkey)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY 
    nc.n_name
ORDER BY 
    total_customer_spending DESC, total_supplies ASC
LIMIT 10;
