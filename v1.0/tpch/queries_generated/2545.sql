WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.total_availqty,
        ps.avg_supplycost
    FROM 
        part p
    JOIN 
        PartSupplierInfo ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    co.c_name,
    hvp.p_name,
    hvp.p_retailprice,
    co.order_count,
    co.total_spent,
    CASE 
        WHEN co.order_count = 0 THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS spend_rank
FROM 
    CustomerOrders co
LEFT JOIN 
    HighValueParts hvp ON co.c_custkey IN (
        SELECT DISTINCT o.o_custkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = hvp.p_partkey
    )
WHERE 
    co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC NULLS LAST;
