WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, 
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS SupplierRank,
           p.p_type,
           p.p_retailprice
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrdersByStatus AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           SUBSTRING(o.o_comment, 1, 10) AS ShortComment,
           COUNT(l.l_orderkey) AS LineItemCount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, o.o_comment
),
HighValueOrders AS (
    SELECT obs.o_orderkey, obs.o_totalprice, obs.ShortComment, 
           RANK() OVER (ORDER BY obs.o_totalprice DESC) AS PriceRank
    FROM OrdersByStatus obs
    WHERE obs.o_totalprice > (SELECT AVG(o_totalprice) FROM OrdersByStatus)
)
SELECT COALESCE(r_supplier.s_name, 'No Supplier') AS SupplierName, 
       r_supplier.p_type AS PartType, 
       HVO.o_orderkey, 
       HVO.o_totalprice, 
       HVO.ShortComment, 
       COALESCE(HVO.PriceRank, 0) AS OrderPriceRank
FROM RankedSupplier r_supplier
FULL OUTER JOIN HighValueOrders HVO ON r_supplier.SupplierRank = HVO.PriceRank
WHERE r_supplier.p_retailprice IS NOT NULL AND 
      (HVO.o_orderstatus = 'F' OR HVO.o_orderstatus IS NULL)
ORDER BY r_supplier.p_type, HVO.o_totalprice DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
