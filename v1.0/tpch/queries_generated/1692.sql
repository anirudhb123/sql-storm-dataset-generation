WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
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
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ss.s_name,
    ss.total_availqty,
    ss.avg_supplycost,
    ps.p_name,
    ps.total_revenue
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    SupplierStats ss ON cs.c_custkey % 10 = ss.s_suppkey % 10  -- Simulating a correlation logic
FULL OUTER JOIN 
    PartSales ps ON ps.total_revenue BETWEEN 1000 AND 10000  -- Filtering revenue range
WHERE 
    cs.order_count > 5 OR ss.total_availqty IS NULL
ORDER BY 
    cs.total_spent DESC, ss.avg_supplycost ASC;
