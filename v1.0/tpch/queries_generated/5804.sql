WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        rc.c_nationkey, 
        rc.c_name, 
        rc.total_revenue
    FROM (
        SELECT 
            c.c_nationkey, 
            c.c_name, 
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM 
            orders o
        JOIN 
            customer c ON o.o_custkey = c.c_custkey
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY 
            c.c_nationkey, c.c_name
        ORDER BY 
            total_revenue DESC
        LIMIT 10
    ) rc
),
NationData AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    t.c_name AS top_customer,
    n.n_name AS nation_name,
    n.total_supplier_balance AS total_balance,
    r.total_revenue AS customer_revenue
FROM 
    TopCustomers t
JOIN 
    NationData n ON t.c_nationkey = n.n_nationkey
JOIN 
    RankedOrders r ON t.c_name = r.c_name
WHERE 
    r.revenue_rank = 1
ORDER BY 
    n.total_supplier_balance DESC, r.customer_revenue DESC;
