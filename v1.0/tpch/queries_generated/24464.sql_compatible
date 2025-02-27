
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(os.total_revenue) AS total_nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    pr.r_name,
    COALESCE(nr.total_nation_revenue, 0) AS total_revenue_for_region,
    RANK() OVER (PARTITION BY pr.r_name ORDER BY COALESCE(nr.total_nation_revenue, 0) DESC) AS revenue_rank,
    SS.s_name AS top_supplier,
    SS.s_acctbal AS top_supplier_balance
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region pr ON n.n_regionkey = pr.r_regionkey
JOIN 
    NationRevenue nr ON n.n_name = nr.n_name
JOIN 
    (SELECT s.s_suppkey, s.s_name, s.s_acctbal 
     FROM RankedSuppliers 
     WHERE rank_within_nation = 1) SS ON s.s_suppkey = SS.s_suppkey
WHERE 
    (p.p_retailprice > 50 OR p.p_comment IS NOT NULL)
    AND NOT EXISTS (SELECT 1 
                    FROM lineitem l 
                    WHERE l.l_partkey = p.p_partkey 
                        AND l.l_returnflag = 'R')
ORDER BY 
    pr.r_name, revenue_rank DESC;
