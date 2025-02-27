WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_order_value
    FROM
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartPricing AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS price_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)

SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    spp.p_name,
    spp.ps_supplycost
FROM 
    CustomerOrderSummary co
JOIN 
    SupplierPartPricing spp ON co.order_count > 5 AND spp.price_rank = 1
WHERE 
    co.total_spent < (SELECT AVG(total_spent) FROM CustomerOrderSummary) 
    AND EXISTS (
        SELECT 1
        FROM lineitem l
        INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = co.c_custkey 
        AND l.l_returnflag = 'N'
        GROUP BY o.o_orderkey
        HAVING SUM(l.l_quantity) > 10
    )
ORDER BY 
    co.total_spent DESC, 
    spp.ps_supplycost ASC;
