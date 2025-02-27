WITH RECURSIVE ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01'
), 
supplier_stats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_totalprice,
    r.r_name AS region_name,
    COALESCE(s.total_available_qty, 0) AS available_qty,
    COALESCE(s.avg_supply_cost, 0) AS average_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS order_sequence,
    CASE 
        WHEN o.o_totalprice > 1000 THEN 'High'
        WHEN o.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS price_category
FROM 
    customer c
JOIN 
    ranked_orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier_stats s ON s.ps_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                          WHERE l.l_orderkey = o.o_orderkey 
                                          LIMIT 1)
WHERE 
    o.rank = 1
ORDER BY 
    o.o_totalprice DESC, c.c_name ASC;
