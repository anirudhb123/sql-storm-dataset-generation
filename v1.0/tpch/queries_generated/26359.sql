WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.supplier_name,
    sd.nation_name,
    od.o_orderkey,
    od.o_orderdate,
    od.total_order_value,
    CASE 
        WHEN od.total_order_value > 10000 THEN 'High Value'
        WHEN od.total_order_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category,
    CONCAT('Supplier ', sd.supplier_name, ' from ', sd.nation_name, ' has processed an order with total value ', ROUND(od.total_order_value, 2), '.') AS message
FROM 
    SupplierDetails sd
JOIN 
    OrderDetails od ON sd.part_count > 5
ORDER BY 
    sd.nation_name, od.total_order_value DESC;
