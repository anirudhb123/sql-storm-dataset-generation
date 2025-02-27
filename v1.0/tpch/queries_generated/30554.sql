WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS varchar(255)) AS HierarchyPath
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CAST(CONCAT(SH.HierarchyPath, ' -> ', s.s_name) AS varchar(255))
    FROM supplier s
    JOIN SupplierHierarchy SH ON s.s_nationkey = SH.s_nationkey
    WHERE s.s_acctbal > 2000 AND s.s_suppkey <> SH.s_suppkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ROI AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        (CASE 
            WHEN ps.total_avail_qty IS NOT NULL THEN ps.total_avail_qty * (1 - L.avg_discount) 
            ELSE 0 
         END) AS predicted_roi,
        ROW_NUMBER() OVER (ORDER BY (CASE 
            WHEN ps.total_avail_qty IS NOT NULL THEN ps.total_avail_qty * L.avg_discount 
            ELSE 0 
        END) DESC) AS part_rank
    FROM part p
    LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN (
        SELECT 
            l.l_partkey, 
            AVG(l.l_discount) AS avg_discount
        FROM lineitem l
        WHERE l.l_shipdate < (CURRENT_DATE - INTERVAL '1 year')
        GROUP BY l.l_partkey
    ) L ON p.p_partkey = L.l_partkey
)
SELECT 
    R.r_name,
    C.c_name,
    C.total_spent,
    RROI.p_name,
    RROI.predicted_roi
FROM region R
JOIN nation N ON R.r_regionkey = N.n_regionkey
JOIN customer C ON C.c_nationkey = N.n_nationkey
JOIN ROI RROI ON RROI.part_rank <= 5
WHERE C.total_spent > 10000 
  AND (C.c_comment IS NULL OR C.c_comment <> '')
ORDER BY R.r_name, C.total_spent DESC;
