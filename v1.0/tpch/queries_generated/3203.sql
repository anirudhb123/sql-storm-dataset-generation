WITH PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.p_brand,
    ps.p_type,
    ps.p_retailprice,
    ps.total_available_quantity,
    ps.avg_supply_cost,
    cs.c_custkey,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    cs.last_order_date
FROM 
    PartSupplierStats ps
LEFT JOIN 
    CustomerOrderStats cs ON ps.p_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_orderstatus = 'O' AND l.l_quantity > 0
    )
WHERE 
    ps.total_available_quantity > 500 
    AND (ps.avg_supply_cost > 15.00 OR ps.p_size BETWEEN 10 AND 20)
ORDER BY 
    ps.p_retailprice DESC,
    cs.total_spent ASC
FETCH FIRST 100 ROWS ONLY;
