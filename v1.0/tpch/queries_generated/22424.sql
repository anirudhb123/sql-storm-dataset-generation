WITH RegionStats AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
CustomerRanked AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acctbal_rank
    FROM 
        customer c
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_price
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
CombinedStats AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        rs.r_name,
        COALESCE(os.order_count, 0) AS order_count,
        ls.net_revenue,
        RANK() OVER (PARTITION BY cs.c_nationkey ORDER BY ls.net_revenue DESC) AS net_revenue_rank
    FROM 
        CustomerRanked cs
    LEFT JOIN 
        OrderStats os ON cs.c_custkey = os.o_custkey
    LEFT JOIN 
        RegionStats rs ON cs.c_nationkey = cs.c_nationkey
    LEFT JOIN 
        LineItemDetails ls ON os.o_custkey = ls.l_orderkey
    WHERE 
        cs.acctbal_rank <= 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    cs.r_name,
    cs.order_count,
    cs.net_revenue,
    CASE 
        WHEN cs.net_revenue IS NULL THEN 'No Revenue'
        WHEN cs.net_revenue > 1000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    CombinedStats cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
WHERE 
    cs.r_name IS NOT NULL
ORDER BY 
    cs.net_revenue DESC, c.c_name ASC;
