WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSalesData AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY p.p_partkey, p.p_name
),
SupplierSales AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT p.p_name, p.total_sales, cs.total_spent, rs.s_name, rs.s_acctbal
FROM PartSalesData p
LEFT JOIN CustomerOrderInfo cs ON cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderInfo)
LEFT JOIN RankedSuppliers rs ON p.p_partkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN SupplierSales s ON p.p_partkey = s.ps_partkey
WHERE p.total_sales > (SELECT AVG(total_sales) FROM PartSalesData)
ORDER BY p.total_sales DESC, cs.total_spent DESC
LIMIT 100;
