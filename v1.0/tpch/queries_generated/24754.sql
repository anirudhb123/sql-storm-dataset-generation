WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, 
           p_size, p_container, p_retailprice, p_comment,
           ROW_NUMBER() OVER(PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rn
    FROM part
    WHERE p_size BETWEEN 1 AND 20
), 
SupplierAvailability AS (
    SELECT ps.partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2020-01-01'
    GROUP BY c.c_custkey
),
HighSpenders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    INNER JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
    AND c.c_acctbal IS NOT NULL
),
PartSupplier AS (
    SELECT rp.p_partkey, ps.ps_suppkey, 
           rp.p_retailprice * ps.ps_supplycost AS modified_cost
    FROM RecursivePart rp
    LEFT JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
)
SELECT 
    ns.n_name,
    SUM(COALESCE(p.total_availqty, 0)) AS total_part_avail,
    AVG(hs.c_acctbal) AS avg_customer_balance
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN PartSupplier p ON s.s_suppkey = p.ps_suppkey
LEFT JOIN HighSpenders hs ON hs.c_custkey = s.s_suppkey
GROUP BY ns.n_name
HAVING SUM(COALESCE(p.total_part_avail, 0)) > 1000
   OR EXISTS (SELECT 1 FROM HighSpenders WHERE c_custkey = s.s_suppkey)
ORDER BY total_part_avail DESC, ns.n_name ASC
LIMIT 10;
