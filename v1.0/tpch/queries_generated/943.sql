WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supply
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationAggregates AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name, 
    ns.supplier_count, 
    ns.total_supplier_balance,
    os.total_orders,
    os.order_count,
    os.average_order_value,
    ss.total_supply_cost,
    ss.unique_parts_supply,
    COALESCE(SUM(ld.net_line_value), 0) AS total_line_item_value
FROM NationAggregates ns
LEFT JOIN OrderSummary os ON ns.n_nationkey = os.c_custkey
LEFT JOIN SupplierSummary ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
LEFT JOIN LineItemDetails ld ON ld.l_orderkey = os.order_count
GROUP BY ns.n_name, ns.supplier_count, ns.total_supplier_balance, os.total_orders, os.order_count, os.average_order_value, ss.total_supply_cost, ss.unique_parts_supply
ORDER BY ns.n_name;
