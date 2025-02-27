WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
overpriced_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        AVG(ps.ps_supplycost) OVER (PARTITION BY p.p_partkey) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
high_volume_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    s.s_name,
    psi.part_count,
    COALESCE(opp.p_name, 'N/A') AS overpriced_part_name,
    COALESCE(opp.p_retailprice, 0) AS overpriced_part_price,
    COALESCE(opp.avg_supply_cost, 0) AS avg_supply_cost,
    hvo.total_quantity AS high_volume_order_qty,
    CASE 
        WHEN hvo.total_quantity IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    supplier_info psi
LEFT JOIN 
    overpriced_parts opp ON psi.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > opp.p_retailprice))
LEFT JOIN 
    high_volume_orders hvo ON hvo.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    psi.rank = 1
ORDER BY 
    total_supply_cost DESC, psi.part_count DESC;
