WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
nations_with_nulls AS (
    SELECT 
        n.n_name AS nation_name, 
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
),
supply_summary AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.nation_name,
    su.total_available_qty,
    su.total_supply_cost,
    ro.o_orderkey,
    ro.total_price,
    CASE 
        WHEN ro.price_rank = 1 THEN 'Highest'
        WHEN ro.price_rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS price_category
FROM 
    region r
JOIN 
    nation_with_nulls n ON r.r_regionkey = n.n_nationkey
LEFT JOIN 
    supply_summary su ON su.p_partkey IN (SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
JOIN 
    ranked_orders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    su.total_available_qty IS NOT NULL AND
    (n.nation_name LIKE 'A%' OR n.nation_name IS NULL) AND
    (ro.total_price > 1000.00 OR ro.total_price IS NULL)
ORDER BY 
    r.r_name, n.nation_name, ro.total_price DESC
LIMIT 100 OFFSET 10;
