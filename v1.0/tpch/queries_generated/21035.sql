WITH valid_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
expensive_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_brand,
        RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS supplier_name,
    ep.p_name AS expensive_part_name,
    ep.p_retailprice AS part_price,
    COALESCE(co.total_order_value, 0) AS customer_total_order_value,
    COUNT(DISTINCT lr.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    valid_suppliers s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    customer_orders co ON co.c_custkey = (SELECT c.c_custkey 
                                             FROM customer c 
                                             WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                    FROM nation n 
                                                                    WHERE n.n_regionkey = (SELECT r.r_regionkey 
                                                                                            FROM region r 
                                                                                            WHERE r.r_name = 'EUROPE') 
                                                                    LIMIT 1) 
                                             LIMIT 1)
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%BIZARRE%')
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    s.s_name, ep.p_name, ep.p_retailprice, co.total_order_value
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem WHERE l_returnflag = 'N')
ORDER BY 
    total_revenue DESC, supplier_name, expensive_part_name;
