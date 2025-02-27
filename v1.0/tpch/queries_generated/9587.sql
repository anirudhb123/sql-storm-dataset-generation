WITH total_revenue AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        p.p_partkey
), supplier_revenue AS (
    SELECT 
        s.s_suppkey,
        SUM(tr.revenue) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        total_revenue tr ON ps.ps_partkey = tr.p_partkey
    GROUP BY 
        s.s_suppkey
), nation_summary AS (
    SELECT 
        n.n_name,
        SUM(sr.total_revenue) AS total_nation_revenue
    FROM 
        nation n
    JOIN 
        supplier_revenue sr ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = sr.s_suppkey)
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.total_nation_revenue,
    ROW_NUMBER() OVER (ORDER BY ns.total_nation_revenue DESC) AS rank
FROM 
    nation_summary ns
WHERE 
    ns.total_nation_revenue > 0
ORDER BY 
    ns.total_nation_revenue DESC;
