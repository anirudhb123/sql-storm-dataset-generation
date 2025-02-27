WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
MaxRevenue AS (
    SELECT 
        o.o_orderkey,
        MAX(total_revenue) AS max_revenue
    FROM 
        OrderSummary o
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    COALESCE(COUNT(DISTINCT n.n_nationkey), 0) AS nation_count,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    SUM(ss.total_supply_cost) AS total_supply_cost,
    AVG(os.unique_customers) AS avg_unique_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    OrderSummary os ON EXISTS (
        SELECT 1 
        FROM MaxRevenue mr 
        WHERE mr.max_revenue > 10000 AND os.o_orderkey = mr.o_orderkey
    )
LEFT JOIN 
    SupplierSummary ss ON ss.ps_partkey IN (
        SELECT 
            p.p_partkey 
        FROM 
            part p 
        WHERE 
            p.p_size > 10 
        AND 
            p.p_comment NOT LIKE '%fragile%'
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
