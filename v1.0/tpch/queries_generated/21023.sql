WITH RegionalAggregates AS (
    SELECT 
        r.r_name AS region_name,
        SUM(case when s.s_acctbal IS NOT NULL then s.s_acctbal else 0 end) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE r.r_name LIKE 'N%' OR r.r_comment IS NOT NULL
    GROUP BY r.r_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS average_supplycost,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
    )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 1000 AND COUNT(o.o_orderkey) > 5
),
JoinedData AS (
    SELECT 
        r.region_name,
        psa.ps_partkey,
        psa.total_availqty,
        hvp.p_name,
        hvp.p_retailprice,
        co.total_spent
    FROM RegionalAggregates r
    JOIN PartSupplierDetails psa ON (1 = 1) -- Cartesian product for illustration
    JOIN HighValueParts hvp ON psa.ps_partkey = hvp.p_partkey 
    LEFT JOIN CustomerOrders co ON (co.order_count IS NOT NULL)
    WHERE r.total_suppliers >= 10 
    OR co.total_spent > (SELECT MAX(total_spent) FROM CustomerOrders) 
)
SELECT 
    jd.region_name,
    jd.p_name, 
    jd.total_availqty, 
    jd.p_retailprice,
    COALESCE(jd.total_spent, 0) AS total_spent_or_zero,
    DENSE_RANK() OVER (PARTITION BY jd.region_name ORDER BY jd.total_availqty DESC) AS rank_by_avail_qty
FROM JoinedData jd
WHERE jd.p_retailprice IS NOT NULL 
AND jd.p_retailprice < (
    SELECT AVG(p3.p_retailprice)
    FROM part p3 WHERE p3.p_size < 50
)
ORDER BY jd.region_name, rank_by_avail_qty;
