WITH FilteredSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, 
           SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > 5000 AND s.s_name LIKE 'Supp%'
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, p.p_retailprice, 
           CONCAT('Manufacturer: ', p.p_mfgr) AS mfgr_comment
    FROM part p
    WHERE p.p_container IN ('BOX', 'PKG') AND p.p_retailprice < 100
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 
           CONCAT('Order Status: ', o.o_orderstatus) AS order_status_comment
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
),
LineItemSummary AS (
    SELECT l.l_orderkey, COUNT(l.l_linenumber) AS lineitem_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    f.s_name,
    f.short_comment,
    p.p_name,
    p.mfgr_comment,
    o.o_orderdate,
    o.o_totalprice,
    o.order_status_comment,
    l.lineitem_count,
    l.total_extended_price
FROM FilteredSupplier f
JOIN PartInfo p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = f.s_suppkey)
JOIN OrderDetails o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = f.s_suppkey)
JOIN LineItemSummary l ON l.l_orderkey = o.o_orderkey
WHERE f.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
ORDER BY o.o_orderdate DESC, l.total_extended_price DESC;