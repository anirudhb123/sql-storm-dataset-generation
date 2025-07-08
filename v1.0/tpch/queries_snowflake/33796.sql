
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE o.o_orderstatus = 'O' AND oh.depth < 5
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice > 1000
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT 
    rh.o_orderkey,
    rh.o_orderdate,
    COALESCE(ps.total_availqty, 0) AS total_avail_qty,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    rp.p_name AS part_name,
    CASE 
        WHEN ho.o_orderkey IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS order_type
FROM OrderHierarchy rh
LEFT JOIN PartSupplierStats ps ON ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rh.o_orderkey LIMIT 1)
LEFT JOIN RankedParts rp ON rp.p_partkey = ps.ps_partkey AND rp.price_rank <= 3
LEFT JOIN HighValueOrders ho ON ho.o_orderkey = rh.o_orderkey
WHERE rh.depth = 1
ORDER BY rh.o_orderdate DESC, rh.o_orderkey;
