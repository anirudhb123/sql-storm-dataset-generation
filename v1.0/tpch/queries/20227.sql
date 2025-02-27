WITH ranked_sales AS (
    SELECT 
        ps_partkey, 
        SUM(ps_supplycost * ps_availqty) AS total_cost, 
        RANK() OVER (PARTITION BY ps_partkey ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS cost_rank
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'NO BALANCE' 
            ELSE CASE 
                WHEN s.s_acctbal < 500 THEN 'LOW BALANCE' 
                ELSE 'HIGH BALANCE' 
                END 
        END AS balance_category
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(rs.total_cost, 0) AS total_cost,
    si.nation_name,
    si.balance_category
FROM 
    part p
LEFT JOIN 
    ranked_sales rs ON p.p_partkey = rs.ps_partkey AND rs.cost_rank = 1
FULL OUTER JOIN 
    supplier_info si ON si.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
WHERE 
    (p.p_retailprice - COALESCE(rs.total_cost, 0)) > 1000 
    OR EXISTS (
        SELECT 1 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = p.p_partkey 
        AND o.o_orderstatus = 'O'
        HAVING SUM(l.l_discount) > 500
    )
ORDER BY 
    p.p_partkey DESC 
FETCH FIRST 50 ROWS ONLY;
