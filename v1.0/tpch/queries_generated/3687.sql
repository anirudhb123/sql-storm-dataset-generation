WITH OrderedSales AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierAvailability AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS customer_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
)
SELECT
    n.n_name AS nation_name,
    COALESCE(SUM(os.total_sales), 0) AS total_order_value,
    COALESCE(SUM(sa.total_available), 0) AS total_available_parts,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers
FROM nation n
LEFT JOIN OrderedSales os ON os.o_orderkey IN (
    SELECT o_orderkey
    FROM orders o1
    JOIN customer c1 ON o1.o_custkey = c1.c_custkey
    WHERE c1.c_nationkey = n.n_nationkey
)
LEFT JOIN SupplierAvailability sa ON sa.p_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey IN (
    SELECT c_custkey
    FROM customer
    WHERE c_nationkey = n.n_nationkey
)
GROUP BY n.n_name
ORDER BY total_order_value DESC, nation_name;
