WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(s.s_comment, 'No comment') AS comment,
        RANK() OVER (ORDER BY s.s_acctbal DESC, s.s_name) AS supply_rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationMetrics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(c.c_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey
)
SELECT 
    rp.p_name,
    rd.s_name AS supplier_name,
    c.total_orders,
    nm.n_name,
    CASE 
        WHEN rd.supply_rank <= 5 THEN 'Top Supplier'
        ELSE 'Other'
    END AS supplier_rank,
    COALESCE(nm.avg_acctbal, 0) AS avg_nation_acctbal,
    (SELECT COUNT(*) 
     FROM lineitem l 
     WHERE l.l_discount = 0.0 AND l.l_returnflag = 'R') AS return_count
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN SupplierDetails rd ON ps.ps_suppkey = rd.s_suppkey
JOIN CustomerOrders c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ps.ps_partkey)
JOIN NationMetrics nm ON nm.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = c.c_custkey)
WHERE rp.price_rank <= 10
AND nm.unique_suppliers > 0
ORDER BY rp.p_name, rd.s_name;
