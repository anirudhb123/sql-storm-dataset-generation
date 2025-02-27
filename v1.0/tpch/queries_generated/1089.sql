WITH SupplyStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
NationSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    COALESCE(s.total_available_quantity, 0) AS available_quantity,
    COALESCE(os.total_order_value, 0) AS order_value,
    ns.nation_name,
    ns.supplier_count,
    CASE 
        WHEN os.total_order_value > 1000 THEN 'High Value'
        WHEN os.total_order_value BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    part p
LEFT JOIN 
    SupplyStats s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    OrderDetails os ON os.total_order_value = s.total_available_quantity -- correlated subquery
LEFT JOIN 
    NationSuppliers ns ON ns.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = os.o_custkey))
WHERE 
    p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1 WHERE p1.p_type = p.p_type)
ORDER BY 
    available_quantity DESC, 
    order_value DESC
LIMIT 100;
