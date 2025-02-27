WITH RECURSIVE price_rank AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS rank
    FROM 
        part
), 
supplier_info AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_acctbal, 
        n_name 
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
order_summary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
supplier_stats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    pr.p_name,
    pr.p_retailprice,
    si.s_name,
    oi.item_count,
    oi.total_revenue,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost
FROM 
    price_rank pr
LEFT JOIN 
    supplier_info si ON si.s_suppkey IN (
        SELECT s_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = pr.p_partkey
    )
LEFT JOIN 
    order_summary oi ON oi.o_orderkey IN (
        SELECT o_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = pr.p_partkey
    )
LEFT JOIN 
    supplier_stats ss ON ss.ps_partkey = pr.p_partkey
WHERE 
    pr.rank <= 5 -- Top 5 priced parts per type
ORDER BY 
    pr.p_partkey, si.s_name, total_revenue DESC;
