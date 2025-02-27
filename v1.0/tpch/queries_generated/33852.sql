WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) as supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 50
),
SalesSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM SalesSummary
    WHERE total_spent > 10000
),
PartSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY l.l_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(ps.total_sales, 0) AS total_sales
    FROM part p
    LEFT JOIN PartSales ps ON p.p_partkey = ps.l_partkey
),
SupplierMetrics AS (
    SELECT sc.s_suppkey, sc.s_name, SUM(sc.ps_supplycost * sc.ps_availqty) AS total_supply_cost,
           AVG(sc.ps_supplycost) AS avg_supply_cost
    FROM SupplyChain sc
    GROUP BY sc.s_suppkey, sc.s_name
)

SELECT ph.p_partkey, ph.p_name, ph.total_sales, ph.p_retailprice,
       COALESCE(sm.total_supply_cost, 0) AS supply_cost,
       CASE
           WHEN ph.total_sales > ph.p_retailprice THEN 'Profitable'
           ELSE 'Not Profitable'
       END AS profitability_status,
       hc.c_name AS high_value_customer
FROM PartDetails ph
LEFT JOIN SupplierMetrics sm ON ph.total_sales > 0
LEFT JOIN HighValueCustomers hc ON ph.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_custkey IN (SELECT c.c_custkey FROM HighValueCustomers c)
    GROUP BY l.l_partkey
)
WHERE ph.total_sales IS NOT NULL
ORDER BY ph.total_sales DESC, ph.p_name ASC;
