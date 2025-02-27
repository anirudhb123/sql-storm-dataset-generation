WITH RECURSIVE ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_order_stats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_discount BETWEEN 0.05 AND 0.10
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    COALESCE(cs.c_name, 'Unknown Customer') AS customer_name,
    rs.s_name AS supplier_name,
    fp.p_name AS part_name,
    fp.avg_price,
    cs.num_orders,
    cs.last_order_date,
    CASE 
        WHEN cs.num_orders >= 10 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS buyer_type,
    CASE 
        WHEN current_date - cs.last_order_date > INTERVAL '1 year' THEN 'Inactive' 
        ELSE 'Active' 
    END AS activity_status
FROM 
    ranked_suppliers rs
FULL OUTER JOIN 
    customer_order_stats cs ON rs.s_suppkey = cs.c_custkey
JOIN 
    filtered_parts fp ON fp.p_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'ManufacturerX' LIMIT 1)
WHERE 
    (rs.s_name IS NOT NULL OR cs.c_name IS NOT NULL)
    AND (fp.avg_price > 100 OR fp.avg_price IS NULL)
ORDER BY 
    rs.total_supply_cost DESC, cs.num_orders DESC, fp.avg_price ASC;
