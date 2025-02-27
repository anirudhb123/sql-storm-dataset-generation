WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
), NationalSupplier AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 1000
    GROUP BY n.n_nationkey, n.n_name
), FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal < 5000
), HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_mfgr
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), OuterJoinSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
), AggregateLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_quantity) > 100
)
SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(s.s_acctbal) AS average_supplier_balance,
    h.p_name AS high_value_part,
    SUM(o.total_price) AS total_order_value,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    ss.available_quantity
FROM RankedOrders o
JOIN FilteredCustomers c ON o.o_custkey = c.c_custkey
JOIN NationalSupplier r ON c.c_nationkey = r.n_nationkey
JOIN HighValueParts h ON o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (SELECT p_partkey FROM part WHERE p_retailprice > 200)
    )
JOIN OuterJoinSuppliers ss ON ss.s_suppkey = (
        SELECT ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p_partkey FROM HighValueParts
        )
        ORDER BY ps.ps_availqty DESC 
        LIMIT 1
    )
GROUP BY r.n_name, h.p_name, ss.available_quantity
ORDER BY nation_name, total_order_value DESC
LIMIT 100 OFFSET 50;
