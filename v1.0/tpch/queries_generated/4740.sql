WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_account_balance,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(p.p_retailprice) AS total_retail_price,
        ROW_NUMBER() OVER (ORDER BY SUM(p.p_retailprice) DESC) AS rank_by_price
    FROM 
        nation n 
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_retail_price,
    ss.s_name,
    ss.total_supply_cost,
    ss.average_account_balance,
    ss.rank_by_cost
FROM 
    NationStats ns
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_nationkey
WHERE 
    ns.supplier_count > 0 AND 
    (ss.total_supply_cost IS NULL OR ss.total_supply_cost > 1000)
ORDER BY 
    ns.total_retail_price DESC, ns.n_name
UNION 
SELECT 
    'Total' AS n_name,
    SUM(n.supplier_count) AS supplier_count,
    SUM(n.total_retail_price) AS total_retail_price,
    NULL AS s_name,
    NULL AS total_supply_cost,
    NULL AS average_account_balance,
    NULL AS rank_by_cost
FROM 
    NationStats n
GROUP BY 
    'Total'
HAVING 
    COUNT(n.n_nationkey) > 0;
