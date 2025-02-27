WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM 
        lineitem l
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(CASE WHEN cl.order_count IS NULL THEN 0 ELSE cl.total_spent END) AS total_customer_spending,
    SUM(COALESCE(st.total_available, 0) * st.total_cost) AS total_supplier_value,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    AVG(CASE WHEN li.rank <= 3 THEN li.l_quantity END) AS avg_top_quantities
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerOrders cl ON n.n_nationkey = cl.c_nationkey
LEFT JOIN 
    SupplierTotals st ON n.n_nationkey = st.s_suppkey
LEFT JOIN 
    RankedLineItems li ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cl.c_custkey)
WHERE 
    r.r_name NOT LIKE '%test%'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT cl.c_custkey) > 5 AND 
    SUM(COALESCE(cl.total_spent, 0)) > 10000
ORDER BY 
    total_supplier_value DESC, 
    total_customer_spending DESC;
