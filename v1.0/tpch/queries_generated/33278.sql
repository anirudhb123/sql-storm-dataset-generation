WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
    UNION ALL
    SELECT co.c_custkey, co.c_name, co.total_spent + li.l_extendedprice
    FROM CustomerOrders co
    JOIN lineitem li ON co.c_custkey = (
        SELECT c.c_custkey
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderkey = li.l_orderkey
        LIMIT 1
    )
    WHERE li.l_shipdate < CURRENT_DATE
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS supplier_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (
        SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL
    )
),
JoinedData AS (
    SELECT co.*, sd.supplier_parts
    FROM CustomerOrders co
    LEFT JOIN SupplierDetails sd ON co.c_custkey = sd.s_suppkey
)
SELECT 
    j.c_custkey, j.c_name, j.total_spent, j.supplier_parts,
    ROW_NUMBER() OVER (PARTITION BY j.c_custkey ORDER BY j.total_spent DESC) AS rn
FROM JoinedData j
JOIN HighValueCustomers hvc ON j.c_custkey = hvc.c_custkey
WHERE j.total_spent IS NOT NULL
ORDER BY j.total_spent DESC
LIMIT 10;
