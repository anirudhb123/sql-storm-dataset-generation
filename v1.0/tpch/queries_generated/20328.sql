WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
),
CustomerTotalSpent AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        STRING_AGG(DISTINCT ps.ps_comment, '; ') AS comments
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM customer c
    JOIN CustomerTotalSpent cts ON c.c_custkey = cts.c_custkey
    WHERE cts.total_spent > (SELECT AVG(total_spent) FROM CustomerTotalSpent)
),
RegionSupplierCounts AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    AVG(COALESCE(cts.total_spent, 0)) AS avg_spent_per_customer,
    MAX(s.total_parts) AS max_parts_per_supplier,
    SUM(su.supplier_count) AS total_suppliers
FROM RegionSupplierCounts su
JOIN HighValueCustomers c ON su.supplier_count > 5
LEFT JOIN CustomerTotalSpent cts ON c.c_custkey = cts.c_custkey
LEFT JOIN SuppliersWithComments s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY num_customers DESC, avg_spent_per_customer DESC
WITHIN GROUP (ORDER BY total_suppliers DESC);
