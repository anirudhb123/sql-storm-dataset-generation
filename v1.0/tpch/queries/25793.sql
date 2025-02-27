WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
        (CASE 
            WHEN LENGTH(s.s_comment) > 50 THEN SUBSTRING(s.s_comment, 1, 50) || '...' 
            ELSE s.s_comment 
        END) AS formatted_comment
    FROM supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_container, 
        p.p_retailprice,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supply_count
    FROM part p
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus, 
        o.o_totalprice,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    od.order_year,
    COUNT(DISTINCT od.o_orderkey) AS num_orders,
    SUM(od.total_value) AS total_revenue,
    STRING_AGG(DISTINCT sd.formatted_comment, '; ') AS supplier_comments
FROM SupplierDetails sd
JOIN PartDetails pd ON sd.s_nationkey = pd.p_partkey
JOIN OrderDetails od ON pd.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey LIMIT 1)
GROUP BY sd.s_name, pd.p_name, od.order_year
HAVING COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY total_revenue DESC;
