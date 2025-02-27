WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
supplier_performance AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_tax) AS avg_tax_rate,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        COUNT(l.l_linenumber) > 5
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(lp.net_revenue, 0) AS net_revenue,
    COALESCE(lp.avg_tax_rate, 0) AS avg_tax_rate,
    COALESCE(lp.line_count, 0) AS line_count,
    sp.total_supply_cost,
    CASE 
        WHEN r.order_rank = 1 THEN 'Top Order'
        ELSE 'Regular Order' 
    END AS order_category
FROM 
    ranked_orders r
LEFT JOIN 
    lineitem_analysis lp ON r.o_orderkey = lp.l_orderkey
LEFT JOIN 
    supplier_performance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey 
                                                FROM partsupp ps 
                                                JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                                WHERE l.l_orderkey = r.o_orderkey 
                                                LIMIT 1)
WHERE 
    r.o_totalprice > (SELECT AVG(o2.o_totalprice) 
                       FROM orders o2 
                       WHERE o2.o_orderstatus = 'O')
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
