WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_available,
        sd.total_supply_value
    FROM SupplierDetails sd
    WHERE sd.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierDetails)
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    hs.s_name AS supplier_name,
    os.total_order_value,
    ns.n_comment,
    COUNT(os.o_orderkey) AS order_count,
    SUM(os.total_order_value) AS total_value,
    CASE 
        WHEN SUM(os.total_order_value) IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM region r
JOIN nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN HighValueSuppliers hs ON hs.s_suppkey = ns.n_nationkey
JOIN OrderSummary os ON os.o_orderkey = hs.s_suppkey
WHERE ns.n_comment IS NOT NULL
GROUP BY r.r_name, ns.n_name, hs.s_name, ns.n_comment
HAVING SUM(os.total_order_value) > 10000
ORDER BY total_value DESC, region, supplier_name;
