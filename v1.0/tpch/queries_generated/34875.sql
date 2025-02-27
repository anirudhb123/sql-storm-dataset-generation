WITH RECURSIVE supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        sd.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_details sd ON s.s_nationkey = sd.s_nationkey
    WHERE 
        sd.level < 3
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
order_status AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(ls.total_revenue) AS total_revenue,
        COUNT(ls.item_count) AS total_items
    FROM 
        orders o
    LEFT JOIN 
        lineitem_summary ls ON o.o_orderkey = ls.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sd.s_name AS supplier_name,
    ns.n_name AS nation_name,
    ns.region_name,
    os.o_orderstatus,
    os.total_revenue,
    os.total_items,
    ROW_NUMBER() OVER (PARTITION BY ns.region_name ORDER BY os.total_revenue DESC) AS revenue_rank,
    COALESCE(sd.level, 0) AS supplier_level
FROM 
    order_status os
JOIN 
    supplier_details sd ON os.o_orderkey IN (
        SELECT p.ps_partkey 
        FROM partsupp p 
        WHERE p.ps_suppkey = sd.s_suppkey 
        AND p.ps_availqty > (
            SELECT AVG(ps_availqty) FROM partsupp WHERE ps_partkey = p.ps_partkey
        )
    )
JOIN 
    nations ns ON sd.s_nationkey = ns.n_nationkey
WHERE 
    os.total_revenue > 1000
ORDER BY 
    ns.region_name, os.total_revenue DESC;
