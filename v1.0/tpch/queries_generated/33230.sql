WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 0 AS lvl
    FROM customer c
    WHERE c.c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.lvl + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 500 AND ch.lvl < 5
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
SupplierCosts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupplier ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_name, COUNT(*) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        DATE_PART('year', o.o_orderdate) AS order_year,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderdate
),
FinalReport AS (
    SELECT 
        ch.c_custkey,
        ch.c_name,
        ns.supplier_count,
        os.total_amount,
        ns.r_name AS region_name,
        CASE 
            WHEN os.item_count > 5 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS order_type
    FROM CustomerHierarchy ch
    LEFT JOIN NationRegion ns ON ch.c_nationkey = ns.n_nationkey
    LEFT JOIN OrderSummary os ON ch.c_custkey = os.o_orderkey
    WHERE ns.supplier_count IS NOT NULL
)
SELECT * FROM FinalReport
WHERE total_amount IS NOT NULL
ORDER BY region_name, total_amount DESC;
