WITH SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
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
NationPerformance AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS nation_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_frequency
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    s.s_name,
    sa.total_cost,
    co.order_count,
    co.total_spent,
    np.nation_revenue,
    np.order_frequency
FROM 
    SupplierAggregate sa
JOIN 
    CustomerOrders co ON sa.num_parts > 5
LEFT JOIN 
    NationPerformance np ON np.nation_revenue IS NOT NULL
WHERE 
    sa.total_cost > (
        SELECT 
            AVG(total_cost) FROM SupplierAggregate
    )
ORDER BY 
    sa.total_cost DESC, co.total_spent DESC;
