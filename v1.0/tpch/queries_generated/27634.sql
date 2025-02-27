WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS region_total
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY region_total DESC
    LIMIT 5
)
SELECT 
    rp.p_brand,
    rp.p_name,
    rp.supplier_count,
    co.c_name,
    co.total_spent,
    tr.r_name,
    tr.region_total
FROM RankedParts rp
JOIN CustomerOrders co ON co.order_count > 0
JOIN TopRegions tr ON tr.r_regionkey IN (
    SELECT n.n_regionkey 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey
    )
)
WHERE rp.rank <= 10
ORDER BY rp.supplier_count DESC, co.total_spent DESC;
