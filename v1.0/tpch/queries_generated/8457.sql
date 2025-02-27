WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'  -- Only considering 'open' orders
    GROUP BY 
        c.c_custkey, c.c_name
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ss.s_name AS supplier_name,
    cs.c_name AS customer_name,
    pr.p_name AS part_name,
    ss.total_cost AS supplier_total_cost,
    cs.total_spent AS customer_total_spent,
    pr.revenue AS part_revenue
FROM 
    SupplierStats ss
JOIN 
    CustomerOrders cs ON ss.unique_parts > 10  -- Supplier must provide more than 10 unique parts
JOIN 
    PartRevenue pr ON pr.revenue > 1000  -- Part revenue must be greater than 1000
ORDER BY 
    supplier_total_cost DESC, customer_total_spent DESC, part_revenue DESC
LIMIT 50;
