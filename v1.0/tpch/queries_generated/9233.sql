WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
)
SELECT sp.s_name, sp.p_brand, sp.p_type, SUM(f.l_quantity) AS total_quantity, SUM(f.l_extendedprice * (1 - f.l_discount)) AS total_revenue
FROM SupplierParts sp
JOIN FilteredLineItems f ON sp.ps_partkey = f.l_partkey
JOIN HighValueCustomers hvc ON f.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hvc.c_custkey)
GROUP BY sp.s_name, sp.p_brand, sp.p_type
ORDER BY total_revenue DESC
LIMIT 10;
