
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
NationSupply AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
)

SELECT 
    rc.o_orderstatus,
    rc.order_count,
    rc.total_revenue,
    tc.c_name AS top_customer,
    tc.total_spent,
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_supply_cost
FROM 
    RankedOrders rc
JOIN 
    TopCustomers tc ON rc.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
JOIN 
    NationSupply ns ON ns.n_name = ANY(SELECT n.n_name FROM nation n WHERE n.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey))
WHERE 
    rc.revenue_rank <= 5
ORDER BY 
    rc.total_revenue DESC;
