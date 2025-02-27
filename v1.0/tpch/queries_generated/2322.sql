WITH RECURSIVE SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderStatistics AS (
    SELECT o.o_orderkey, o.o_custkey, TOTAL_VALUE, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TOTAL_VALUE
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT DISTINCT
    p.p_name,
    p.p_brand,
    p.p_container,
    SUM(ps.ps_availqty) AS total_available_qty,
    COALESCE(SUM(oi.TOTAL_VALUE), 0) AS total_order_value,
    rc.r_name AS region_name,
    CASE 
        WHEN SUM(ps.ps_availqty) BETWEEN 100 AND 500 THEN 'Moderate'
        WHEN SUM(ps.ps_availqty) > 500 THEN 'High'
        ELSE 'Low'
    END AS availability_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region rc ON n.n_regionkey = rc.r_regionkey
LEFT JOIN OrderStatistics oi ON oi.o_custkey IN (SELECT c_custkey FROM HighValueCustomers WHERE cust_rank <= 5)
GROUP BY p.p_name, p.p_brand, p.p_container, rc.r_name
HAVING SUM(ps.ps_availqty) IS NOT NULL AND AVG(oi.TOTAL_VALUE) > 1000
ORDER BY total_order_value DESC, availability_status;
