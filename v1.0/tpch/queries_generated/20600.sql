WITH recursive order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
nation_supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
),
part_revenue AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    ns.n_name,
    os.o_orderkey,
    os.o_orderstatus,
    os.line_count,
    os.total_revenue,
    pr.total_supply_cost
FROM 
    nation_supplier ns
JOIN 
    order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ns.n_name)))
LEFT JOIN 
    part_revenue pr ON pr.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
WHERE 
    os.rn = 1
ORDER BY 
    ns.n_name, os.total_revenue DESC
LIMIT 100 OFFSET 10;
