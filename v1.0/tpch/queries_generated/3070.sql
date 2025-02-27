WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), 
NationRevenue AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(sos.total_revenue), 0) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        SupplierOrderStats sos ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sos.s_suppkey)
    GROUP BY 
        n.n_nationkey, n.n_name
), 
RevenueRanked AS (
    SELECT 
        nr.n_name,
        nr.total_revenue,
        RANK() OVER (ORDER BY nr.total_revenue DESC) AS revenue_rank
    FROM 
        NationRevenue nr
)
SELECT 
    pr.p_partkey,
    pr.p_name,
    pr.p_brand,
    pr.p_retailprice,
    COALESCE(rr.total_revenue, 0) AS nationwide_revenue,
    rr.revenue_rank
FROM 
    part pr
LEFT JOIN 
    RevenueRanked rr ON pr.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rr.n_name)))
WHERE 
    pr.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2 
        WHERE p2.p_type = pr.p_type
    )
ORDER BY 
    rr.revenue_rank, pr.p_partkey;
