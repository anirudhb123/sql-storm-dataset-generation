
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_supply_cost
    FROM 
        supplier AS s
    JOIN 
        supplier_summary AS ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_summary)
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey,
        l.l_extendedprice, 
        l.l_discount,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        EXTRACT(WEEK FROM l.l_shipdate) AS ship_week
    FROM 
        lineitem AS l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
)
SELECT 
    DISTINCT ro.o_orderkey,
    ro.o_orderdate,
    ro.c_mktsegment,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    ts.s_name AS top_supplier_name,
    ROW_NUMBER() OVER (ORDER BY ro.o_orderdate DESC) AS order_rank
FROM 
    ranked_orders AS ro
LEFT JOIN 
    lineitem_analysis AS l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    top_suppliers AS ts ON l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE 
    ro.price_rank <= 10
GROUP BY 
    ro.o_orderkey, ro.o_orderdate, ro.c_mktsegment, ts.s_name
ORDER BY 
    net_revenue DESC;
