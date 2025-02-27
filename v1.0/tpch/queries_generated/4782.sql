WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS lineitem_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        os.o_custkey,
        os.total_revenue
    FROM 
        OrderStatistics os
    WHERE 
        os.revenue_rank <= 10
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(si.total_supply_cost) AS total_supply_cost,
    AVG(o.o_totalprice) AS average_order_value,
    MAX(o.o_orderdate) AS latest_order_date
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    TopCustomers tc ON c.c_custkey = tc.o_custkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierInfo si ON si.s_nationkey = n.n_nationkey
WHERE 
    (n.n_name IS NOT NULL AND c.c_custkey IS NOT NULL) OR
    (tc.o_custkey IS NULL AND o.o_orderstatus = 'F')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_supply_cost DESC;
