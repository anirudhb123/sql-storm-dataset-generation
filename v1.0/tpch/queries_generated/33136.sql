WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    UNION ALL
    SELECT co.c_custkey, co.c_name, co.total_spent + o.o_totalprice
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderkey NOT IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_orderstatus = 'F')
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
)
SELECT 
    s.s_name AS supplier_name,
    r.nation_name,
    pp.p_name AS part_name,
    pp.p_partkey,
    co.total_spent AS customer_spent,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    CASE 
        WHEN ps.total_available IS NULL THEN 0
        ELSE ps.total_available 
    END AS available_quantity,
    CASE 
        WHEN co.total_spent > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_category
FROM SupplierDetails s
LEFT JOIN RankedParts pp ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN PartSuppliers ps ON pp.p_partkey = ps.ps_partkey
LEFT JOIN CustomerOrders co ON s.s_suppkey = co.c_custkey
LEFT JOIN orders o ON co.c_custkey = o.o_custkey
WHERE r.n_name IS NOT NULL
GROUP BY s.s_name, r.nation_name, pp.p_name, pp.p_partkey, co.total_spent
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY co.total_spent DESC, number_of_orders DESC;
