WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name,
           p.p_size,
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
), SuppliersWithDiscount AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000.00
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           o.o_orderkey,
           o.o_totalprice,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
), SuspiciousOrders AS (
    SELECT DISTINCT co.o_orderkey,
                    co.c_name,
                    CASE WHEN co.net_price IS NULL THEN 'NO_ORDER' 
                         ELSE CASE 
                              WHEN co.net_price > 500 THEN 'HIGH_VALUE' 
                              ELSE 'LOW_VALUE' END
                    END AS order_value
    FROM CustomerOrders co
    WHERE co.o_orderdate < (SELECT CURRENT_DATE - INTERVAL '1 year')
), FinalReport AS (
    SELECT r.r_name,
           COUNT(DISTINCT so.o_orderkey) AS suspicious_orders_count,
           AVG(sp.total_supply_cost) AS average_supply_cost,
           MAX(rp.p_retailprice) AS max_part_price,
           MIN(rp.p_retailprice) AS min_part_price
    FROM region r
    LEFT JOIN SuspiciousOrders so ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN customer c ON n.n_nationkey = c.c_nationkey
        WHERE c.c_custkey = so.c_name
        LIMIT 1
    )
    LEFT JOIN SuppliersWithDiscount sp ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey IN (SELECT p_partkey FROM RankedParts WHERE rn <= 10)
        )
        LIMIT 1
    )
    JOIN RankedParts rp ON rp.p_partkey = (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_size IS NOT NULL AND p.p_size > 0
        ORDER BY RANDOM() 
        LIMIT 1
    )
    GROUP BY r.r_name
)
SELECT r_name,
       suspicious_orders_count,
       average_supply_cost,
       COALESCE(max_part_price, 0) AS max_part_price,
       COALESCE(min_part_price, 0) AS min_part_price
FROM FinalReport
HAVING AVG(average_supply_cost) > (SELECT AVG(total_supply_cost) FROM SuppliersWithDiscount)
ORDER BY suspicious_orders_count DESC, r_name ASC;
