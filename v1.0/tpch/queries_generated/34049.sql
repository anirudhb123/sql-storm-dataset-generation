WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 as level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier_hierarchy sh
    JOIN 
        supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal > 0 AND sh.level < 5
),

latest_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM 
        orders o
),

lineitem_stats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(*) AS item_count,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    nl.n_name AS nation_name,
    COALESCE(ls.total_price, 0) AS total_price,
    COALESCE(ss.s_acctbal, 0) AS supplier_balance,
    CASE WHEN ls.item_count > 0 THEN 'Has Orders' ELSE 'No Orders' END AS order_status,
    sh.level AS supplier_level
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation nl ON s.s_nationkey = nl.n_nationkey
LEFT JOIN 
    lineitem_stats ls ON ls.l_orderkey = (
        SELECT o.o_orderkey
        FROM latest_orders o
        WHERE o.o_custkey = ANY(SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nl.n_nationkey)
        ORDER BY o.o_orderdate DESC
        LIMIT 1
    )
LEFT JOIN 
    supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100 AND 
    (sh.level IS NULL OR sh.level <= 3)
ORDER BY 
    p.p_partkey ASC, total_price DESC;
