WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_parts_supplied,
        ss.total_supply_value,
        n.n_name AS nation_name
    FROM SupplierStats ss
    JOIN nation n ON ss.s_nationkey = n.n_nationkey
    WHERE ss.rn <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderSummary AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.nation_name,
        COUNT(DISTINCT lo.o_orderkey) AS total_orders,
        AVG(lo.o_totalprice) AS avg_order_value
    FROM TopSuppliers ts
    LEFT JOIN lineitem li ON li.l_suppkey = ts.s_suppkey
    LEFT JOIN HighValueOrders lo ON li.l_orderkey = lo.o_orderkey
    GROUP BY ts.s_suppkey, ts.s_name, ts.nation_name
)
SELECT 
    sos.s_suppkey,
    sos.s_name,
    sos.nation_name,
    COALESCE(sos.total_orders, 0) AS total_orders,
    COALESCE(sos.avg_order_value, 0.00) AS avg_order_value,
    CONCAT(sos.s_name, ' from ', sos.nation_name) AS supplier_info
FROM SupplierOrderSummary sos
ORDER BY sos.total_orders DESC, sos.avg_order_value DESC;
