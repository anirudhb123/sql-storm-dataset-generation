WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_phone, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
    FROM part p
    WHERE p.p_retailprice > 100.00 AND LOWER(p.p_name) LIKE '%widget%'
),
OrderDetails AS (
    SELECT o.o_orderkey, c.c_name, o.o_totalprice, o.o_orderdate, o.o_orderpriority, o.o_comment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 500.00
),
LineItemAggregates AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    od.c_name AS customer_name,
    oa.total_revenue,
    oa.item_count,
    od.o_orderpriority,
    sd.nation_name,
    pd.p_type,
    pd.p_retailprice,
    od.o_orderdate
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN OrderDetails od ON od.o_orderkey IN (SELECT l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey)
JOIN LineItemAggregates oa ON od.o_orderkey = oa.l_orderkey
WHERE sd.s_acctbal > 1000.00
ORDER BY oa.total_revenue DESC, sd.s_name ASC;
