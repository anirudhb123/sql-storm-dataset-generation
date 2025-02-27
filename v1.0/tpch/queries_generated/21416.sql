WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS lvl
    FROM supplier s 
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.lvl + 1 
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.lvl < 10
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_available,
        AVG(p.p_retailprice) AS avg_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerNegBalance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal, 
        CASE WHEN c.c_acctbal < 0 THEN 'OVERDRAWN' ELSE 'NORMAL' END AS account_status
    FROM customer c
    WHERE c.c_acctbal < 0
),
OrderTotalByRegion AS (
    SELECT 
        n.n_regionkey,
        SUM(o.o_totalprice) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ph.lvl AS supplier_level,
    COALESCE(ct.account_status, 'NO CUSTOMER') AS account_status,
    ot.total_order_value,
    CASE WHEN ot.total_order_value > 100000 THEN 'HIGH VALUE' 
         WHEN ot.total_order_value BETWEEN 50000 AND 100000 THEN 'MEDIUM VALUE' 
         ELSE 'LOW VALUE' END AS value_category,
    CASE WHEN p.p_size IS NULL THEN 'UNKNOWN SIZE' ELSE CAST(p.p_size AS VARCHAR) END AS size_info
FROM PartInfo p
LEFT JOIN SupplierHierarchy ph ON p.p_partkey = ph.s_suppkey
LEFT JOIN CustomerNegBalance ct ON p.p_partkey = ct.c_custkey
LEFT JOIN OrderTotalByRegion ot ON p.p_partkey = ot.n_regionkey
WHERE p.total_available > 0
  AND (p.avg_price > 100.00 OR ot.total_order_value IS NULL)
ORDER BY supplier_level DESC, p.p_name;
