WITH RECURSIVE price_differences AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ps.ps_supplycost - p.p_retailprice AS cost_difference
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
    UNION ALL
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ps.ps_supplycost - p.p_retailprice
    FROM 
        price_differences pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        pd.cost_difference < 0
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.cost_difference,
    co.total_spent,
    co.order_count,
    r.r_name
FROM 
    price_differences pd
LEFT JOIN 
    supplier s ON pd.ps_supplycost = s.s_acctbal
LEFT JOIN 
    customer_orders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    pd.cost_difference < 0
    AND co.order_count > 5
    AND (co.total_spent IS NOT NULL OR co.order_count IS NOT NULL)
ORDER BY 
    pd.cost_difference DESC, 
    co.total_spent DESC 
LIMIT 100;
