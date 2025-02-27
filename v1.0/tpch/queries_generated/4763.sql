WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierPerformance AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_suppkey
),
CombinedPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(sp.total_available, 0) AS total_available,
        COALESCE(sp.avg_cost, 0) AS avg_cost,
        SUM(os.total_revenue) AS total_revenue
    FROM 
        supplier s
    LEFT JOIN 
        SupplierPerformance sp ON s.s_suppkey = sp.ps_suppkey
    LEFT JOIN 
        OrderSummary os ON os.o_orderkey = (
            SELECT o_orderkey 
            FROM orders 
            WHERE o_custkey = s.s_suppkey
            ORDER BY o_orderdate DESC 
            LIMIT 1
        )
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, sp.total_available, sp.avg_cost
)
SELECT 
    c.c_name,
    cp.total_available,
    cp.avg_cost,
    cp.total_revenue,
    RANK() OVER (ORDER BY cp.total_revenue DESC) AS revenue_rank
FROM 
    CombinedPerformance cp
JOIN 
    customer c ON cp.s_suppkey = c.c_custkey
WHERE 
    cp.total_revenue > (SELECT AVG(total_revenue) FROM CombinedPerformance) 
    OR cp.avg_cost IS NULL
ORDER BY 
    revenue_rank;
