WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
           SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierInfo AS (
    SELECT s.s_suppkey,
           s.s_name,
           n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC NULLS LAST) AS rank_by_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, 
           o.o_totalprice,
           SUM(li.l_extendedprice * (1 - li.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_net_price,
           COUNT(li.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
)
SELECT rp.p_name,
       rp.total_cost,
       si.nation_name,
       od.total_net_price,
       od.line_count,
       CASE 
           WHEN od.total_net_price IS NULL THEN 'No Sales'
           WHEN rp.rank_price <= 5 AND si.rank_by_acctbal <= 3 THEN 'Top Part & Supplier'
           ELSE 'Other'
       END AS classification
FROM RankedParts rp
LEFT JOIN SupplierInfo si ON rp.p_partkey = (SELECT ps.ps_partkey 
                                               FROM partsupp ps 
                                               WHERE ps.ps_supplycost = (SELECT MAX(ps_inner.ps_supplycost) 
                                                                          FROM partsupp ps_inner 
                                                                          WHERE ps_inner.ps_partkey = rp.p_partkey)
                                               FETCH FIRST 1 ROW ONLY)
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey 
                                                FROM orders o 
                                                JOIN lineitem li ON o.o_orderkey = li.l_orderkey 
                                                WHERE li.l_partkey = rp.p_partkey)
WHERE rp.rank_price <= 10
ORDER BY rp.total_cost DESC, si.nation_name ASC NULLS LAST
LIMIT 50 OFFSET 0;
