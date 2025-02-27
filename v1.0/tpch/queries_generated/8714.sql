WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), order_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus, 
        o.o_orderdate
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        l.l_orderkey, o.o_orderstatus, o.o_orderdate
), ranked_suppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        ss.nation,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        supplier_summary ss
)
SELECT 
    os.o_orderkey, 
    os.total_revenue, 
    rs.s_name AS top_supplier, 
    rs.nation,
    os.o_orderstatus,
    os.o_orderdate
FROM 
    order_summary os
JOIN 
    ranked_suppliers rs ON os.o_orderdate = (SELECT MAX(o_orderdate) FROM orders WHERE o_orderstatus = 'F' AND o_orderdate <= os.o_orderdate)
WHERE 
    rs.rank = 1 
ORDER BY 
    os.total_revenue DESC
LIMIT 10;
