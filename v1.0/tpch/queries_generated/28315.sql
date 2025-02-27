WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           STRING_AGG(DISTINCT CONCAT_WS(' ', p.p_name, p.p_brand) ORDER BY p.p_name) AS part_names
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment
    FROM nation n
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal,
           COUNT(o.o_orderkey) AS order_count,
           STRING_AGG(DISTINCT o.o_orderstatus ORDER BY o.o_orderstatus) AS unique_order_statuses
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal
)
SELECT sd.s_name, nd.n_name, cd.c_name, cd.order_count, 
       cd.unique_order_statuses, sd.part_names
FROM SupplierDetails sd
JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
JOIN CustomerDetails cd ON nd.n_nationkey = cd.c_nationkey
WHERE sd.s_acctbal > 1000
ORDER BY sd.s_name, cd.order_count DESC;
