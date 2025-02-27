WITH RECURSIVE SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = ps.ps_partkey
    )
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice,
           COUNT(l.l_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_quantity,
           ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name,
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
)
SELECT p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice,
       COALESCE(sp.ps_availqty, 0) AS max_avail_qty,
       COALESCE(sp.ps_supplycost, 0) AS min_supply_cost,
       t.total_orders, t.total_revenue, t.avg_quantity,
       ts.s_name AS supplier_name, ts.r_name AS supplier_region
FROM PartDetails p
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey AND sp.rn = 1
JOIN TopSuppliers ts ON ts.s_supplierkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
)
WHERE (p.total_revenue > 5000 AND p.revenue_rank <= 10)
   OR (p.avg_quantity IS NULL OR p.avg_quantity < 10)
ORDER BY p.p_retailprice DESC, p.total_orders DESC;
