WITH Supply_Stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
Order_Stats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    ss.s_supplier_nation,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    SUM(ss.total_available_qty) AS total_supply,
    SUM(os.total_revenue) AS total_order_revenue,
    AVG(os.total_quantity) AS avg_order_quantity,
    MAX(os.o_totalprice) AS max_order_price
FROM 
    Supply_Stats ss
JOIN 
    Order_Stats os ON ss.s_supplier_nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = os.o_orderkey LIMIT 1))
GROUP BY 
    ss.s_supplier_nation
ORDER BY 
    total_order_revenue DESC;
