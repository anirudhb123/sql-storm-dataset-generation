WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2022-01-01' 
        AND l.l_shipdate < '2023-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000 OR COUNT(o.o_orderkey) > 5
)
SELECT 
    n.n_name,
    COALESCE(SUM(pr.total_revenue), 0) AS total_part_revenue,
    COUNT(DISTINCT co.c_custkey) AS num_customers,
    COUNT(DISTINCT rs.s_suppkey) AS num_suppliers
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rank <= 5
LEFT JOIN 
    PartRevenue pr ON pr.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    )
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F'
    )
GROUP BY 
    n.n_name
HAVING 
    COALESCE(SUM(pr.total_revenue), 0) > 5000
ORDER BY 
    total_part_revenue DESC, num_customers DESC;
