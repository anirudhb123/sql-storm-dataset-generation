WITH OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        os.o_orderkey, 
        os.o_orderdate, 
        os.total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(MONTH FROM os.o_orderdate) ORDER BY os.total_revenue DESC) AS monthly_rank
    FROM 
        OrderSummary os
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN ro.monthly_rank <= 5 THEN ro.o_orderkey ELSE NULL END) AS top_order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_size > 10 AND 
    s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    region_name, nation_name, supplier_name;
