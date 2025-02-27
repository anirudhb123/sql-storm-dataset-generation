WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
ExpensiveParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           LEAD(p.p_retailprice) OVER (ORDER BY p.p_retailprice DESC) AS next_price
    FROM part p
    WHERE p.p_retailprice > 1000
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice,
           RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank,
           (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey) AS item_count
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierParts AS (
    SELECT DISTINCT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    LEFT JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE sd.rn = 1 OR sd.rn IS NULL
),
FinalReport AS (
    SELECT os.o_orderkey, os.o_totalprice, os.item_count, 
           ep.p_name,
           sp.ps_supplycost * 1.1 AS adjusted_supply_cost,
           CASE WHEN os.item_count > 10 THEN 'Bulk' ELSE 'Single' END AS order_type
    FROM OrderSummary os
    LEFT JOIN lineitem li ON os.o_orderkey = li.l_orderkey
    LEFT JOIN ExpensiveParts ep ON li.l_partkey = ep.p_partkey
    LEFT JOIN SupplierParts sp ON ep.p_partkey = sp.ps_partkey
    WHERE (ep.next_price IS NULL OR ep.next_price < ep.p_retailprice * 1.5)
      AND (sp.ps_availqty IS NOT NULL OR sp.ps_supplycost < 500)
)
SELECT fr.o_orderkey, fr.o_totalprice, fr.item_count, fr.p_name,
       COALESCE(fr.adjusted_supply_cost, 0) AS adjusted_cost,
       fr.order_type,
       CONCAT('Order ', fr.o_orderkey, ' total: ', fr.o_totalprice, 
              ' | Item Count: ', fr.item_count, 
              ' | Part: ', COALESCE(fr.p_name, 'No Part'), 
              ' | Adjusted Supply Cost: ', COALESCE(fr.adjusted_supply_cost, 'Not applicable')) AS detailed_info
FROM FinalReport fr
WHERE fr.o_totalprice > (SELECT AVG(o_totalprice) FROM OrderSummary)
ORDER BY fr.o_totalprice DESC
LIMIT 50;
