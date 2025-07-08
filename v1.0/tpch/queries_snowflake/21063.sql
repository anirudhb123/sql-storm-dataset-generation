
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High'
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            ELSE 'Low'
        END AS customer_value
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM orders o
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        COALESCE(ps.ps_availqty / NULLIF(NULLIF(ps.ps_supplycost,0), NULL), 1, 1) AS supply_rate
    FROM partsupp ps
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.s_name,
    h.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.total_revenue) AS total_revenue,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names,
    ARRAY_AGG(DISTINCT n.n_name) AS supplying_nations
FROM RankedSuppliers r
FULL OUTER JOIN HighValueCustomers h ON r.s_suppkey = h.c_custkey
LEFT JOIN RecentOrders o ON h.c_custkey = o.o_custkey
INNER JOIN LineItemSummary l ON o.o_orderkey = l.l_orderkey
CROSS JOIN nation n
LEFT JOIN partsupp ps ON r.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE 
    (r.rn <= 3 OR h.customer_value = 'High')
    AND (COALESCE(r.s_acctbal, 0) > 5000 OR n.n_regionkey IS NULL)
GROUP BY r.s_name, h.c_name
HAVING SUM(l.total_revenue) IS NOT NULL OR COUNT(o.o_orderkey) > 0
ORDER BY total_revenue DESC NULLS LAST;
