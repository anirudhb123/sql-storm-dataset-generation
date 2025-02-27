WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), ranked_customers AS (
    SELECT 
        co.c_custkey, 
        co.c_name,
        co.total_spent,
        ROW_NUMBER() OVER (PARTITION BY co.c_nationkey ORDER BY co.total_spent DESC) AS rank
    FROM 
        customer_orders co 
), supplier_part_info AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    rc.c_name AS customer_name,
    rc.total_spent AS customer_total_spent,
    spi.total_available AS supplier_supply_qty,
    spi.avg_supply_cost AS avg_cost
FROM 
    ranked_customers rc
JOIN 
    nation n ON rc.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier_part_info spi ON spi.ps_suppkey = (SELECT ps_suppkey 
                                                  FROM partsupp 
                                                  WHERE ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20 ORDER BY p.p_retailprice DESC LIMIT 1) 
                                                  LIMIT 1)
WHERE 
    rc.rank <= 5
ORDER BY 
    r.r_name, rc.total_spent DESC;
