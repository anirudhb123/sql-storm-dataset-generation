WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_discount) AS total_discount,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
),
FilteredCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, r.r_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        ps.ps_availqty,
        RANK() OVER (ORDER BY ps.ps_supplycost ASC) AS rank_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
)

SELECT 
    fh.cust_key, 
    fh.cust_name, 
    fh.region_name, 
    so.o_orderkey, 
    so.total_discount,
    ps.p_partkey,
    ps.p_name,
    ps.avail_qty,
    sh.level AS supplier_level
FROM FilteredCustomer fh
JOIN RankedOrders so ON fh.c_custkey = so.o_custkey
FULL OUTER JOIN PartSupplier ps ON ps.ps_suppkey = so.o_custkey
JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_suppkey
WHERE (fh.total_spent > 20000 OR sh.level = 1)
AND (ps.avail_qty IS NOT NULL AND ps.avail_qty > 10)
ORDER BY fh.region_name, so.o_orderkey DESC, sh.level;
