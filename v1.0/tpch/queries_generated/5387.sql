WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SalesSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(cp.total_sales) AS total_sales_per_supplier
    FROM SupplierParts s
    JOIN CustomerOrders cp ON s.p_partkey = cp.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT ss.s_name, ss.total_sales_per_supplier, COUNT(DISTINCT cp.o_orderkey) AS order_count
FROM SalesSummary ss
JOIN CustomerOrders cp ON ss.s_suppkey = cp.o_orderkey
WHERE ss.total_sales_per_supplier > 100000
ORDER BY ss.total_sales_per_supplier DESC, order_count ASC
LIMIT 10;
