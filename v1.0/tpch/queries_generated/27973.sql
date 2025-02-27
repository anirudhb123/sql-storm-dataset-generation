WITH FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
    FROM part p
    WHERE LENGTH(p.p_name) > 10 AND p.p_retailprice > 100.00
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_phone, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000.00
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
),
PartSuppSummary AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 100
)
SELECT 
    fp.p_name, 
    fp.p_brand, 
    fp.p_retailprice, 
    si.s_name AS supplier_name, 
    si.nation_name, 
    co.c_name AS customer_name,
    co.o_orderdate, 
    co.o_totalprice,
    pss.total_avail_qty
FROM FilteredParts fp
JOIN PartSuppSummary pss ON fp.p_partkey = pss.ps_partkey
JOIN SupplierInfo si ON pss.ps_suppkey = si.s_suppkey
JOIN CustomerOrders co ON co.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = fp.p_partkey
)
ORDER BY fp.p_name, co.o_orderdate DESC;
