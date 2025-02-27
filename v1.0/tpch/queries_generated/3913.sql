WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_acct_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
PartStats AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_container,
        AVG(ps_supplycost) AS avg_supply_cost,
        SUM(ps_availqty) AS total_avail_qty
    FROM 
        part
    JOIN 
        partsupp ON part.p_partkey = partsupp.ps_partkey
    GROUP BY 
        p_partkey, p_name, p_brand, p_container
),
OrderStats AS (
    SELECT 
        o_custkey,
        COUNT(DISTINCT o_orderkey) AS total_orders,
        SUM(o_totalprice) AS total_spent
    FROM 
        orders
    WHERE 
        o_orderstatus = 'F'
    GROUP BY 
        o_custkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s_stats.total_suppliers,
    s_stats.total_acct_balance,
    p_stats.p_name,
    p_stats.avg_supply_cost,
    p_stats.total_avail_qty,
    o_stats.total_orders,
    o_stats.total_spent
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats s_stats ON n.n_nationkey = s_stats.s_nationkey
LEFT JOIN 
    PartStats p_stats ON p_stats.p_partkey = (
        SELECT 
            ps.partkey
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp WHERE ps.partkey = p_stats.p_partkey)
        LIMIT 1
    )
LEFT JOIN 
    OrderStats o_stats ON o_stats.o_custkey = (
        SELECT 
            c.c_custkey
        FROM 
            customer c 
        WHERE 
            c.c_nationkey = n.n_nationkey
        ORDER BY 
            c.c_acctbal DESC
        LIMIT 1
    )
WHERE 
    (s_stats.total_suppliers IS NOT NULL OR p_stats.total_avail_qty > 1000)
    AND r.r_name IS NOT NULL
ORDER BY 
    r.r_name, n.n_name, total_spent DESC;
