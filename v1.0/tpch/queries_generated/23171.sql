WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1
),
OrderDetail AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_availqty,
    ps.avg_supplycost,
    od.order_total,
    od.item_count,
    ns.nation_name,
    ns.supplier_count AS total_suppliers,
    CASE 
        WHEN ns.total_acctbal IS NULL THEN 'No Accounts'
        ELSE 'With Accounts'
    END AS account_status,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY ps.avg_supplycost ASC) AS ranking
FROM PartStats ps
JOIN OrderDetail od ON ps.p_partkey = od.item_count
LEFT JOIN nation n ON n.n_nationkey IN (SELECT DISTINCT s_nationkey FROM SupplierHierarchy)
LEFT JOIN (
    SELECT n_name, supplier_count FROM NationSummary
) ns ON n.r_regionkey = ns.supplier_count
WHERE (
    ps.total_availqty IS NOT NULL OR ps.avg_supplycost IS NOT NULL
) AND 
EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_nationkey = n.n_nationkey AND s.s_acctbal > 1000
)
ORDER BY ranking DESC, ps.p_name;
