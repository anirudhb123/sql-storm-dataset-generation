
WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_item_count,
        SUM(l.l_extendedprice) AS total_order_value,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus, o.o_custkey
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ss.total_supply_cost) AS total_supply_cost_per_nation
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier_summary ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_regionkey
)
SELECT 
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_supply_cost_per_nation,
    os.line_item_count,
    os.total_order_value,
    os.o_orderstatus
FROM 
    nation_summary ns
JOIN 
    order_summary os ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_custkey)
WHERE 
    ns.total_supply_cost_per_nation > 10000
ORDER BY 
    os.total_order_value DESC, ns.supplier_count ASC;
