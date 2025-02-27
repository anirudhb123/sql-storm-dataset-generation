WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, 0 AS level
    FROM part
    WHERE p_size <= 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size = ph.p_size + 5
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supplycost, SUM(ps.ps_availqty) AS total_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, cos.total_spent
    FROM customer c
    JOIN CustomerOrderSummary cos ON c.c_custkey = cos.c_custkey
    WHERE cos.total_spent > 10000
)
SELECT 
    ph.p_name,
    ph.p_retailprice,
    s.s_name,
    ss.avg_supplycost,
    c.c_name AS high_value_customer,
    COALESCE(cos.total_spent, 0) AS customer_spending,
    ROW_NUMBER() OVER (PARTITION BY ph.p_name ORDER BY ss.total_availqty DESC) AS rn
FROM PartHierarchy ph
LEFT JOIN SupplierStats ss ON ph.p_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (
        SELECT s_suppkey FROM supplier WHERE s_acctbal > 5000
    )
)
LEFT JOIN HighValueCustomers c ON c.c_custkey IN (
    SELECT o.o_custkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_quantity > 100
)
WHERE ph.level < 3
ORDER BY ph.p_retailprice DESC, c.c_name;
