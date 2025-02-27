
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(*) OVER(PARTITION BY p.p_brand) AS total_per_brand
    FROM 
        part p
),
SuppliersWithDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal <= 0 THEN 'Negative Balance' 
            ELSE 'Positive Balance' 
        END AS balance_status,
        ROW_NUMBER() OVER(ORDER BY s.s_acctbal DESC) AS rank_supplier
    FROM 
        supplier s
)
SELECT 
    np.n_name,
    MAX(np.total_orders) AS max_orders,
    STRING_AGG(DISTINCT pp.p_name, ', ') AS highly_priced_parts,
    COALESCE(MAX(sp.s_name), 'No Supplier') AS top_supplier_name
FROM (
    SELECT 
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        orders o ON p.p_partkey = o.o_orderkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        n.n_name
) np
FULL OUTER JOIN (
    SELECT 
        rank_price.p_partkey,
        rank_price.p_name,
        rank_price.p_retailprice
    FROM 
        RankedParts rank_price
    WHERE 
        rank_price.rank_price <= 3
) pp ON np.n_name IS NOT NULL AND pp.p_partkey IS NOT NULL
LEFT JOIN (
    SELECT 
        swd.s_name, 
        swd.s_acctbal 
    FROM 
        SuppliersWithDetails swd 
    WHERE 
        swd.rank_supplier = 1
) sp ON np.n_name IS NOT NULL AND sp.s_acctbal IS NOT NULL
GROUP BY 
    np.n_name
HAVING 
    MAX(np.total_orders) > 0
ORDER BY 
    CASE 
        WHEN MAX(np.total_orders) IS NULL THEN 1 
        ELSE 0 
    END, 
    np.n_name;
