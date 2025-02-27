WITH PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice, 
           p.p_comment,
           CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand) AS part_brand_info,
           LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_retailprice > 100
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_phone,
           s.s_acctbal,
           SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal >= 5000
),
FilteredOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           CONCAT('Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d'), ', Total Price: $', FORMAT(o.o_totalprice, 2)) AS order_info
    FROM orders o
    WHERE o.o_totalprice < 10000
)
SELECT pd.part_brand_info, 
       sd.s_name, 
       sd.s_phone, 
       fo.order_info
FROM PartDetails pd
JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN FilteredOrders fo ON fo.o_orderkey = ps.ps_partkey
ORDER BY pd.p_retailprice DESC, sd.s_acctbal DESC;
