WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_address, s2.nationkey, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(*) AS item_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
SupplierProducts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, SUM(ps.ps_availqty) AS total_avail
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, co.total_spent,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY co.total_spent DESC) AS spend_rank
    FROM CustomerOrders co
    JOIN customer c ON c.c_custkey = co.c_custkey
),
FilteredSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, COUNT(DISTINCT p.p_partkey) AS product_count
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY sh.s_suppkey, sh.s_name
)

SELECT rc.c_name, rc.total_spent, rc.spend_rank, 
       fs.s_name AS supplier_name, fs.product_count,
       l.max_value AS max_order_value
FROM RankedCustomers rc
LEFT JOIN FilteredSuppliers fs ON rc.c_nationkey = fs.s_suppkey
LEFT JOIN (
    SELECT o.o_orderkey, MAX(l.total_value) AS max_value
    FROM LineItemStats l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
) AS l ON l.o_orderkey = rc.c_custkey
WHERE rc.spend_rank <= 10
ORDER BY rc.total_spent DESC, fs.product_count ASC;
