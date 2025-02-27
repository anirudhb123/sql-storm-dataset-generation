WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost DESC) AS supplier_rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    co.total_orders,
    co.total_spent,
    s.p_name,
    s.p_brand,
    s.p_retailprice,
    s.total_cost,
    ro.o_orderdate,
    ro.order_rank
FROM CustomerOrders co
JOIN SupplierPartDetails s ON co.total_orders > 5
LEFT JOIN RankedOrders ro ON co.total_orders = (SELECT COUNT(*) FROM orders WHERE o_custkey = co.c_custkey)
WHERE s.supplier_rank <= 3
  AND (s.p_retailprice > 100 OR NULLIF(co.total_spent, 0) IS NULL)
ORDER BY co.total_spent DESC, s.p_brand ASC;
