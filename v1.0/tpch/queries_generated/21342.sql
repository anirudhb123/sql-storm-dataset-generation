WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            WHEN o.o_orderstatus IS NULL OR o.o_orderstatus = '' THEN 'Unknown'
            ELSE 'Pending'
        END AS status_desc
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
LineItemSummary AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
        COUNT(*) AS total_items,
        COUNT(DISTINCT li.l_suppkey) AS unique_suppliers
    FROM lineitem li
    WHERE li.l_shipdate >= '2021-01-01'
    GROUP BY li.l_orderkey
)

SELECT 
    co.c_custkey,
    co.o_orderkey,
    co.o_orderdate,
    co.status_desc,
    su.s_name AS top_supplier,
    COALESCE(ranked.total_items, 0) AS total_items_in_order,
    COALESCE(ranked.net_revenue, 0) AS total_revenue
FROM CustomerOrders co
LEFT JOIN LineItemSummary ranked ON co.o_orderkey = ranked.l_orderkey
LEFT JOIN RankedSuppliers su ON su.rn = 1 AND su.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_type LIKE '%Metal%' AND p.p_size > 10
)
WHERE EXISTS (
    SELECT 1
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
    AND r.r_comment IS NOT NULL AND r.r_comment <> ''
)
ORDER BY co.o_orderdate DESC, total_revenue DESC
LIMIT 100;
