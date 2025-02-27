WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           CONCAT(s.s_name, ' - ', s.s_address, ' (', s.s_phone, ')') AS SupplierInfo,
           STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', r.r_name), '; ') AS NationRegionInfo
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_container, 
           p.p_retailprice, 
           CONCAT(p.p_name, ' - ', p.p_brand, ' (', p.p_container, ')') AS PartInfo
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
OrderStatistics AS (
    SELECT o.o_orderkey, 
           o.o_totalprice, 
           o.o_orderdate, 
           COUNT(li.l_orderkey) AS LineItemCount
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT sd.SupplierInfo, 
       pd.PartInfo, 
       os.o_orderkey, 
       os.o_totalprice, 
       os.LineItemCount
FROM SupplierDetails sd
CROSS JOIN PartDetails pd
JOIN OrderStatistics os ON os.LineItemCount > 5
ORDER BY os.o_totalprice DESC, sd.s_acctbal ASC
LIMIT 100;
