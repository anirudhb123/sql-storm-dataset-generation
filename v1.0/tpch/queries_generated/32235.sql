WITH RECURSIVE SupplierPartCTE AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty * 2 AS ps_availqty,
        ps.ps_supplycost * 0.9 AS ps_supplycost,
        level + 1
    FROM partsupp ps
    JOIN SupplierPartCTE sp ON ps.ps_partkey = sp.ps_partkey
    WHERE level < 5
),
TotalInventory AS (
    SELECT 
        part.p_partkey,
        part.p_name,
        SUM(sp.ps_availqty) AS total_available,
        SUM(sp.ps_supplycost) AS total_cost
    FROM part
    LEFT JOIN SupplierPartCTE sp ON part.p_partkey = sp.ps_partkey
    GROUP BY part.p_partkey, part.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent,
        cust.total_orders,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS rank
    FROM CustomerOrders cust
    WHERE cust.total_spent IS NOT NULL AND cust.total_orders > 0
)
SELECT 
    p.p_partkey,
    p.p_name,
    ti.total_available,
    ti.total_cost,
    rc.c_name AS frequent_customer,
    rc.total_spent,
    rc.rank
FROM part p
JOIN TotalInventory ti ON p.p_partkey = ti.p_partkey
LEFT JOIN RankedCustomers rc ON rc.total_orders >= 10
WHERE (ti.total_available < 100 AND rc.rank <= 10) OR ti.total_cost > 500
ORDER BY ti.total_available ASC, rc.total_spent DESC;
