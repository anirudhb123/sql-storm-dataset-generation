WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.customer_count,
        os.o_orderdate,
        os.revenue_rank,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS rank
    FROM 
        OrderSummary os
    WHERE 
        os.revenue_rank < 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    AVG(DISTINCT os.total_revenue) AS avg_revenue,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN 
    TopOrders os ON os.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
WHERE 
    (p.p_size > 10 OR p.p_size IS NULL)
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, ps.ps_availqty
ORDER BY 
    avg_revenue DESC;
