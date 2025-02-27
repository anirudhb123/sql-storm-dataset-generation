WITH NationwideSupplierStats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        SUM(s.s_acctbal) AS total_account_balance,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(o.o_orderdate) AS latest_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.nation_name,
    ns.unique_suppliers,
    ns.total_account_balance,
    ns.total_parts_supplied,
    ns.total_inventory_value,
    od.total_order_value,
    od.part_count,
    od.latest_order_date
FROM 
    NationwideSupplierStats ns
JOIN 
    OrderDetails od ON ns.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = od.part_count)))
ORDER BY 
    ns.total_inventory_value DESC, 
    od.total_order_value DESC 
LIMIT 10;
