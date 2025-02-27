WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrdersWithHighValue AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_status_text
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2
    )
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(*) AS total_lineitems
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    pr.p_name,
    sr.s_name,
    sr.nation_name,
    sr.region_name,
    o.o_orderkey,
    o.order_status_text,
    li.total_lineitem_value,
    li.total_lineitems
FROM RankedParts pr
JOIN SupplierRegion sr ON sr.supplier_rank <= 3
LEFT JOIN OrdersWithHighValue o ON o.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
)
LEFT JOIN LineItemSummary li ON li.l_orderkey = o.o_orderkey
WHERE pr.part_rank = 1
  AND (sr.region_name IS NOT NULL OR sr.nation_name IS NULL)
ORDER BY pr.p_name, sr.s_name;
