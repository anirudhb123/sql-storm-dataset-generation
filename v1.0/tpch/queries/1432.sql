
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierAvgCosts AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
CustomerCountByRegion AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    R.o_orderkey,
    R.o_orderdate,
    R.total_revenue,
    COALESCE(S.avg_cost, 0) AS avg_cost,
    C.customer_count,
    CASE 
        WHEN R.revenue_rank = 1 THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_category
FROM 
    RankedOrders R
LEFT JOIN 
    SupplierAvgCosts S ON S.ps_suppkey = (SELECT ps.ps_suppkey 
                                            FROM partsupp ps 
                                            JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                            WHERE l.l_orderkey = R.o_orderkey 
                                            ORDER BY ps.ps_supplycost DESC
                                            LIMIT 1)
LEFT JOIN 
    CustomerCountByRegion C ON C.nation_name = (SELECT n.n_name 
                                                 FROM nation n 
                                                 JOIN customer c ON n.n_nationkey = c.c_nationkey 
                                                 WHERE c.c_custkey = R.o_orderkey
                                                 LIMIT 1)
WHERE 
    R.total_revenue > 1000
ORDER BY 
    R.o_orderdate DESC, R.total_revenue DESC;
