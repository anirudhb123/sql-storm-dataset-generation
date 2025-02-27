WITH RECURSIVE price_distribution AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.p_retailprice) OVER () AS median_price
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    AVG(co.total_spent) AS avg_spent_per_customer,
    SUM(sp.total_supply_cost) AS total_supply_cost,
    MAX(pd.p_retailprice) AS max_part_price,
    AVG(pd.median_price) OVER () AS overall_median_price
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    customer_orders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    supplier_parts sp ON sp.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
        )
    )
LEFT JOIN 
    price_distribution pd ON pd.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps
        WHERE ps.ps_suppkey = sp.s_suppkey
    )
GROUP BY 
    n.n_name 
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
ORDER BY 
    avg_spent_per_customer DESC;
