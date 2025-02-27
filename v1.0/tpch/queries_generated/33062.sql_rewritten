WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
),
part_supplier_stats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    pt.total_available,
    pt.avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE l.l_extendedprice 
        END) AS total_revenue,
    COUNT(DISTINCT CASE 
                        WHEN c.c_mktsegment = 'BUILDING' THEN o.o_orderkey 
                    END) AS building_orders,
    MAX(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_shipdate 
        ELSE NULL 
    END) AS latest_return_date
FROM 
    part p
JOIN 
    part_supplier_stats pt ON p.p_partkey = pt.p_partkey 
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    p.p_retailprice < 100
    AND (l.l_shipdate IS NULL OR l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '30 days')
GROUP BY 
    p.p_partkey, p.p_name, pt.total_available, pt.avg_supply_cost
HAVING 
    SUM(l.l_quantity) > 0
ORDER BY 
    pt.avg_supply_cost DESC, total_revenue DESC;