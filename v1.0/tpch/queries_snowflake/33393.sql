
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
PartAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
BestSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_sales,
        p.total_available,
        p.avg_supply_price
    FROM SupplierPerformance sp
    JOIN PartAvailability p ON sp.total_sales > p.avg_supply_price * 100
),
FinalReport AS (
    SELECT 
        ch.c_custkey,
        ch.c_name,
        sh.s_name AS top_supplier,
        ch.total_spent,
        RANK() OVER (PARTITION BY ch.c_custkey ORDER BY ch.total_spent DESC) AS spending_rank,
        COALESCE(sh.level, 0) AS supplier_tier,
        ROW_NUMBER() OVER (ORDER BY ch.total_spent DESC) AS report_row
    FROM CustomerOrders ch
    LEFT JOIN SupplierHierarchy sh ON ch.c_custkey = sh.s_nationkey
    WHERE ch.order_count > 5
)
SELECT 
    fr.report_row,
    fr.c_custkey,
    fr.c_name,
    fr.top_supplier,
    fr.total_spent,
    fr.spending_rank,
    fr.supplier_tier
FROM FinalReport fr
WHERE fr.supplier_tier > 1
ORDER BY fr.total_spent DESC, fr.report_row;
