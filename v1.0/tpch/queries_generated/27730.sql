WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           LENGTH(p.p_name) AS name_length, 
           p.p_brand, 
           REGEXP_REPLACE(p.p_comment, '\\s+', ' ') AS clean_comment
    FROM part p
),
SupplierNation AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           n.n_name AS nation_name, 
           s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, 
           o.o_totalprice, 
           o.o_orderdate, 
           c.c_name AS customer_name, 
           c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000
)
SELECT rp.p_name, 
       rp.name_length, 
       sn.nation_name, 
       hv.customer_name, 
       hv.o_totalprice, 
       hv.o_orderdate
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN SupplierNation sn ON ps.ps_suppkey = sn.s_suppkey
JOIN HighValueOrders hv ON EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_orderkey = hv.o_orderkey AND l.l_partkey = rp.p_partkey
)
ORDER BY rp.name_length DESC, hv.o_totalprice DESC
LIMIT 50;
