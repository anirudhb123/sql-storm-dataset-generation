WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5 
), 
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 100.00
    GROUP BY c.c_custkey, c.c_name
), 
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_partkey) AS part_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalReport AS (
    SELECT
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.total_orders,
        p.total_supply_cost,
        lid.part_count,
        lid.total_price_after_discount,
        DENSE_RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) as rank
    FROM CustomerOrder co
    LEFT JOIN PartSupplier p ON co.c_custkey = p.p_partkey
    LEFT JOIN LineItemDetails lid ON co.total_orders = lid.l_orderkey
)
SELECT
    fr.c_custkey,
    fr.c_name,
    fr.total_spent,
    fr.total_orders,
    fr.total_supply_cost,
    fr.part_count,
    fr.total_price_after_discount
FROM FinalReport fr
WHERE fr.rank = 1
ORDER BY fr.total_spent DESC
LIMIT 10;
