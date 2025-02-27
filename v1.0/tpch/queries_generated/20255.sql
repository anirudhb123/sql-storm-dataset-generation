WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS depth
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        depth + 1
    FROM 
        customer_orders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate > (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_custkey = co.c_custkey) 
        AND o.o_orderstatus = 'O'
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        pp.p_partkey,
        pp.p_retailprice,
        ps.ps_supplycost,
        pp.p_name || ' - ' || ps.ps_comment AS part_info,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part pp ON ps.ps_partkey = pp.p_partkey
    WHERE 
        pp.p_size BETWEEN 1 AND 20 
        AND s.s_acctbal IS NOT NULL 
),
final_summary AS (
    SELECT 
        co.c_name,
        SUM(co.o_totalprice) AS total_spent,
        COUNT(DISTINCT co.o_orderkey) AS order_count,
        COUNT(DISTINCT sp.part_info) AS unique_parts,
        AVG(sp.p_retailprice) AS avg_price,
        MAX(sp.ps_supplycost) AS max_supply_cost
    FROM 
        customer_orders co
    LEFT JOIN 
        supplier_parts sp ON co.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey LIMIT 1)
    GROUP BY 
        co.c_name
)
SELECT 
    fs.c_name,
    fs.total_spent,
    fs.order_count,
    fs.unique_parts,
    fs.avg_price,
    fs.max_supply_cost,
    CASE 
        WHEN fs.total_spent > 1000 THEN 'High Roller'
        WHEN fs.total_spent IS NULL THEN 'No Activity'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    final_summary fs
WHERE 
    fs.avg_price IS NOT NULL
    AND fs.max_supply_cost > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
ORDER BY 
    fs.total_spent DESC
LIMIT 10;

