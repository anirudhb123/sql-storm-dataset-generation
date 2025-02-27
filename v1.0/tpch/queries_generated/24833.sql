WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
suppliers_with_max_cost AS (
    SELECT 
        ps.ps_partkey, 
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
nation_orders AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        orders o ON s.s_suppkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
),
filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        (CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending' 
         END) AS order_status_desc
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
        AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
supply_details AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name,
    COALESCE(sd.total_available_qty, 0) AS total_qty_available,
    COALESCE(sd.supplier_count, 0) AS supplier_count,
    fo.order_count,
    fo.total_revenue
FROM 
    ranked_parts p
LEFT JOIN 
    supply_details sd ON p.p_partkey = sd.ps_partkey
FULL OUTER JOIN 
    nation_orders fo ON p.price_rank <= 5 AND p.p_partkey IN (SELECT ps_partkey FROM suppliers_with_max_cost)
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = fo.n_nationkey)
WHERE 
    p.p_retailprice BETWEEN (SELECT MIN(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL) 
                       AND (SELECT MAX(p3.p_retailprice) FROM part p3 WHERE p3.p_size IS NOT NULL)
ORDER BY 
    p.p_name, total_qty_available DESC;
