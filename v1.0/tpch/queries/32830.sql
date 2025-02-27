WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_retailprice
    FROM part
    WHERE p_size > 15
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_retailprice
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey
    WHERE p.p_retailprice < ph.p_retailprice * 0.9
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    ph.p_name AS part_name,
    ph.p_brand AS part_brand,
    sd.s_name AS supplier_name,
    sd.total_supplier_cost AS supplier_cost,
    os.o_totalprice AS order_total_price,
    os.total_quantity AS total_quantity,
    ROW_NUMBER() OVER (PARTITION BY ph.p_name ORDER BY sd.total_supplier_cost DESC) AS rank_supplier
FROM PartHierarchy ph
LEFT JOIN SupplierDetails sd ON ph.p_partkey = sd.s_nationkey
LEFT JOIN OrderStats os ON os.total_quantity = (SELECT MAX(total_quantity) FROM OrderStats)
WHERE ph.p_retailprice IS NOT NULL
  AND (sd.total_supplier_cost IS NOT NULL OR sd.total_supplier_cost = 0)
ORDER BY ph.p_name, sd.total_supplier_cost DESC;
