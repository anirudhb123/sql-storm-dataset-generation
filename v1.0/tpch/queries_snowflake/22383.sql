
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS total_items
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_size BETWEEN 20 AND 30
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
nation_details AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    np.n_name,
    np.region_name,
    rp.p_name,
    rp.p_retailprice,
    si.total_supply_cost,
    si.avg_acct_balance,
    CASE 
        WHEN si.total_supply_cost > 100 THEN 'High Supply Cost'
        ELSE 'Low Supply Cost'
    END AS supply_cost_category,
    COUNT(DISTINCT o.o_orderkey) AS completed_orders
FROM 
    ranked_parts rp
JOIN 
    supplier_info si ON rp.p_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost = (
            SELECT MAX(ps2.ps_supplycost) 
            FROM partsupp ps2 
            WHERE ps2.ps_partkey = rp.p_partkey
        ) 
        LIMIT 1
    )
JOIN 
    nation_details np ON si.s_nationkey = np.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = np.n_nationkey 
        LIMIT 1
    )
WHERE 
    rp.rank_price <= 5
AND 
    np.supplier_count >= 1
GROUP BY 
    np.n_name, np.region_name, rp.p_name, rp.p_retailprice, si.total_supply_cost, si.avg_acct_balance
HAVING 
    SUM(rp.p_retailprice) BETWEEN 150 AND 500
ORDER BY 
    np.n_name ASC, rp.p_retailprice DESC;
