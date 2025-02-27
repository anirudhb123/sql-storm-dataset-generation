WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(MAX(sp.total_available_qty), 0) AS max_available_qty,
        COALESCE(MIN(sp.max_supply_cost), 0) AS min_supply_cost
    FROM part p
    LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    rp.s_suppkey,
    rp.s_name,
    ph.p_partkey,
    ph.p_name,
    ph.max_available_qty,
    ph.min_supply_cost,
    hvo.total_order_value
FROM RankedSuppliers rp
FULL OUTER JOIN PartSupplierDetails ph ON rp.s_suppkey = ph.p_partkey
FULL OUTER JOIN HighValueOrders hvo ON hvo.o_orderkey = ph.p_partkey
WHERE (rp.suppplier_rank <= 5 OR ph.max_available_qty > 100) AND hvo.total_order_value IS NOT NULL
ORDER BY rp.s_suppkey, hvo.total_order_value DESC, ph.p_name;
