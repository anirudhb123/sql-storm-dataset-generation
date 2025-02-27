WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, h.level + 1
    FROM region r
    INNER JOIN RegionHierarchy h ON r.r_regionkey = h.r_regionkey + 1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (ORDER BY SUM(co.total_spent) DESC) AS rank
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT rh.r_name, ns.n_name, r.c_name, rc.rank, s.total_available
FROM RegionHierarchy rh
FULL OUTER JOIN NationSummary ns ON rh.r_regionkey = ns.n_nationkey
JOIN RankedCustomers rc ON ns.supplier_count = rc.rank
LEFT JOIN SupplierParts s ON rc.c_custkey = s.s_suppkey
WHERE s.total_available IS NOT NULL AND rc.c_acctbal > 10000
ORDER BY rc.rank, rh.level DESC, ns.n_name;
