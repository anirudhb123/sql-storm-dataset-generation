WITH recursive nation_ranks AS (
    SELECT 
        n.n_name,
        n.n_nationkey,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_region
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name, n.n_nationkey, r.r_name
), 
part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(s.s_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 10 AND 
        (p.p_retailprice BETWEEN 100 AND 500 OR p.p_brand LIKE 'A%')
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
), 
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    pr.p_name AS part_name,
    os.total_value,
    os.item_count,
    nr.rank_within_region,
    COALESCE(pr.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN os.total_value IS NULL THEN 'No Orders'
        WHEN os.total_value > 10000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_category
FROM 
    nation_ranks nr
INNER JOIN 
    nation n ON nr.n_nationkey = n.n_nationkey
LEFT JOIN 
    part_details pr ON pr.p_partkey IN (
        SELECT ps.p_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > (
            SELECT AVG(ps2.ps_availqty) 
            FROM partsupp ps2 
            WHERE ps2.ps_partkey = ps.ps_partkey
        )
    )
LEFT JOIN 
    order_summary os ON os.o_orderkey = (SELECT MIN(o.o_orderkey) 
                                           FROM orders o 
                                           WHERE o.o_custkey IN (
                                               SELECT c.c_custkey 
                                               FROM customer c 
                                               WHERE c.c_nationkey = n.n_nationkey
                                           ))
WHERE 
    nr.rank_within_region = 1
ORDER BY 
    n.n_name, pr.p_name;
