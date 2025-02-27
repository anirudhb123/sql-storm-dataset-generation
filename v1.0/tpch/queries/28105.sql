WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size,
           p.p_container, p.p_retailprice, p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE LENGTH(p.p_name) > 10
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 
           SUBSTRING(s.s_comment, 1, 30) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > 5000.00
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           CONCAT(c.c_name, ' - ', o.o_orderkey) AS customer_order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
AggregatedData AS (
    SELECT np.n_name, COUNT(DISTINCT co.o_orderkey) AS total_orders,
           SUM(l.l_extendedprice - l.l_discount) AS total_revenue,
           STRING_AGG(DISTINCT pp.p_name, ', ') AS part_names
    FROM nation np
    JOIN supplier s ON np.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RankedParts pp ON ps.ps_partkey = pp.p_partkey
    JOIN lineitem l ON pp.p_partkey = l.l_partkey
    JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
    GROUP BY np.n_name
)
SELECT ad.n_name, ad.total_orders, ad.total_revenue, ad.part_names
FROM AggregatedData ad
WHERE ad.total_orders > 5 AND ad.total_revenue > 10000.00
ORDER BY ad.total_revenue DESC;
