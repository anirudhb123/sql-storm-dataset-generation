WITH RECURSIVE Supplier_Orders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Customer_Purchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
),
Part_Suppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
        COALESCE(MAX(ps.ps_supplycost), 0) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    so.s_name AS supplier_name,
    cp.c_name AS customer_name,
    ps.p_name AS part_name,
    ps.total_available,
    ps.max_supply_cost,
    so.total_revenue,
    cp.order_count,
    cp.total_spent
FROM 
    Supplier_Orders so
FULL OUTER JOIN 
    Customer_Purchases cp ON so.revenue_rank = cp.order_count
FULL OUTER JOIN 
    Part_Suppliers ps ON ps.max_supply_cost > 0
WHERE 
    (so.total_revenue IS NOT NULL OR cp.total_spent IS NOT NULL)
    AND ps.total_available > 10
ORDER BY 
    so.total_revenue DESC, cp.total_spent DESC;
