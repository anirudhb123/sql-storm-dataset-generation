WITH SupplierCosts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS supplied_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATEADD(month, -6, GETDATE()) AND GETDATE()
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT 
    s.s_name,
    sc.total_supply_cost,
    od.c_name,
    od.total_price,
    od.o_orderdate,
    od.order_rank
FROM SupplierCosts sc
LEFT JOIN OrderDetails od ON od.c_custkey IN (SELECT c.c_custkey FROM HighValueCustomers c)
WHERE sc.total_supply_cost IS NOT NULL
  AND od.total_price IS NOT NULL
ORDER BY sc.total_supply_cost DESC, od.total_price DESC;
