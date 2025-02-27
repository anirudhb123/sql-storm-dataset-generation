WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
NationRegion AS (
    SELECT 
        n.n_name as nation_name,
        r.r_name as region_name,
        COUNT(*) AS nation_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
),
QualifiedParts AS (
    SELECT 
        pp.p_partkey, 
        pp.p_name,
        pp.p_brand,
        ps.ps_supplycost
    FROM RankedParts pp
    LEFT JOIN partsupp ps ON pp.p_partkey = ps.ps_partkey
    WHERE pp.rn <= 5
),
CustomerPerformance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(os.total_spent, 0) AS total_spent,
        os.order_count,
        CASE 
            WHEN COALESCE(os.total_spent, 0) > 10000 THEN 'High Value'
            WHEN COALESCE(os.total_spent, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)

SELECT 
    cp.c_custkey,
    cp.c_name,
    cp.total_spent,
    cp.customer_segment,
    rp.p_name AS top_part_name,
    rp.p_retailprice AS top_part_price,
    sd.s_name AS supplier_name,
    sd.s_acctbal AS supplier_balance,
    nr.nation_name,
    nr.region_name
FROM CustomerPerformance cp
LEFT JOIN QualifiedParts rp ON cp.total_spent > 5000
LEFT JOIN SupplierDetails sd ON sd.supplier_rank = 1 AND sd.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
)
JOIN NationRegion nr ON cp.c_custkey = (SELECT c_nationkey FROM customer WHERE c_custkey = cp.c_custkey)
WHERE cp.customer_segment <> 'Low Value'
ORDER BY cp.total_spent DESC, rp.p_retailprice DESC
LIMIT 10;
