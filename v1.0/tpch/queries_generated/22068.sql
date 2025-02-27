WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 30
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comments') AS effective_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    p.p_name AS part_name,
    sp.s_name AS supplier_name,
    co.order_count,
    co.total_spent,
    RANK() OVER (PARTITION BY r.r_name ORDER BY co.total_spent DESC) AS rank_in_region
FROM RankedParts p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierInfo sp ON ps.ps_suppkey = sp.s_suppkey
JOIN nation n ON sp.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN CustomerOrders co ON co.order_count > 0
WHERE p.rank_by_price <= 5
  AND (sp.effective_comment IS NOT NULL OR sp.s_acctbal IS NOT NULL)
  AND EXISTS (
      SELECT 1 
      FROM lineitem l
      WHERE l.l_partkey = p.p_partkey 
        AND l.l_quantity IS NOT NULL 
        AND l.l_discount BETWEEN 0.05 AND 0.20 
        AND l.l_returnflag = 'R'
  )
ORDER BY rank_in_region, total_spent DESC
LIMIT 10;
