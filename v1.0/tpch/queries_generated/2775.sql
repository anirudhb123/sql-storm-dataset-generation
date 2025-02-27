WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    COALESCE(SUM(s.total_available), 0) AS total_available_quantity,
    COALESCE(SUM(cr.customer_revenue), 0) AS total_customer_revenue,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    SupplierStats s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    CustomerRevenue cr ON p.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_suppkey IN (
            SELECT s.s_suppkey
            FROM supplier s
            JOIN nation n ON s.s_nationkey = n.n_nationkey
            JOIN region r ON n.n_regionkey = r.r_regionkey
            WHERE r.r_name LIKE 'N%'
        )
    )
LEFT JOIN 
    nation n ON s.ps_suppkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(s.total_available) > 100 AND COALESCE(SUM(cr.customer_revenue), 0) > 5000
ORDER BY 
    total_customer_revenue DESC, total_available_quantity DESC;
