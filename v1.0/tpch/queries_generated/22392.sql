WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_desc,
        COUNT(*) OVER () AS total_count
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
PartPrices AS (
    SELECT 
        p.p_partkey,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice BETWEEN 10.00 AND 50.00 THEN 'Moderate'
            WHEN p.p_retailprice < 10.00 THEN 'Cheap'
            ELSE 'Expensive'
        END AS price_category
    FROM part p
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    co.c_custkey,
    co.order_count,
    po.price_category,
    sa.total_available,
    ro.o_orderstatus,
    CASE 
        WHEN ro.rank_desc <= 3 THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_rank_status
FROM CustomerOrders co
JOIN PartPrices po ON co.order_count = (SELECT COUNT(*) FROM orders o WHERE o.o_orderstatus = 'F' AND o.o_orderkey = co.c_custkey)
LEFT JOIN SupplierAvailability sa ON sa.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp))
LEFT OUTER JOIN RankedOrders ro ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = co.c_custkey AND o.o_orderstatus = 'F')
WHERE po.price_category != 'Moderate' 
AND (sa.total_available IS NULL OR sa.total_available > 50)
ORDER BY co.order_count DESC, ro.o_orderstatus ASC;
