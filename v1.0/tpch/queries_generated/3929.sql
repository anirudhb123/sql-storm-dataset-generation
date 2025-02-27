WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(cs.total_spent) AS avg_customer_spending,
    SUM(ld.revenue) AS total_revenue,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ld.revenue) DESC) AS revenue_rank
FROM 
    nation n
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierStats cs ON cs.s_suppkey = s.s_suppkey
LEFT JOIN 
    LineItemDetails ld ON ld.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#45')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 AND
    SUM(ld.revenue) IS NOT NULL
ORDER BY 
    revenue_rank;
