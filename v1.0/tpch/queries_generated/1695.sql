WITH supplier_agg AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    n.n_name AS supplier_nation,
    s.s_name AS supplier_name,
    sa.total_avail_qty,
    hc.total_spent,
    ls.total_line_value,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY sa.total_avail_qty DESC) AS rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    supplier_agg sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN 
    high_value_customers hc ON hc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN 
    lineitem_summary ls ON ls.l_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey ORDER BY l.l_extendedprice DESC LIMIT 1)
WHERE 
    p.p_retailprice > 20.00
AND 
    (hc.total_spent IS NOT NULL OR sa.total_avail_qty IS NOT NULL)
ORDER BY 
    n.n_name, p.p_name;
