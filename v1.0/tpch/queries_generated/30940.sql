WITH RECURSIVE top_suppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        RANK() OVER (ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier
    WHERE 
        s_acctbal IS NOT NULL
),
recent_orders AS (
    SELECT 
        o_custkey,
        COUNT(o_orderkey) AS order_count,
        SUM(o_totalprice) AS total_spent,
        AVG(o_totalprice) AS avg_order_value
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o_custkey
),
supplier_part_details AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(ro.order_count, 0) AS order_count,
    COALESCE(ro.total_spent, 0.00) AS total_spent,
    COALESCE(ro.avg_order_value, 0.00) AS avg_order_value,
    spd.p_name,
    spd.p_brand,
    spd.p_retailprice,
    spd.ps_supplycost,
    spd.ps_availqty
FROM 
    customer c
LEFT JOIN 
    recent_orders ro ON c.c_custkey = ro.o_custkey
JOIN 
    supplier_part_details spd ON spd.supplier_rank = 1
WHERE 
    c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
    AND spd.ps_availqty > 0
    AND c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment IS NOT NULL)
ORDER BY 
    c.c_name, spd.p_retailprice DESC
LIMIT 50;
