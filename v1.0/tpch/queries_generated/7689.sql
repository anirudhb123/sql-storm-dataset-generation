WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderstatus,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CombinedStats AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        os.o_orderkey,
        os.total_order_value,
        os.o_orderdate,
        ss.total_supply_cost,
        ss.parts_supplied,
        os.line_item_count
    FROM 
        SupplierStats ss
    JOIN 
        OrderSummary os ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                            FROM partsupp ps 
                                            WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                                                                    FROM lineitem l 
                                                                    WHERE l.l_orderkey = os.o_orderkey)
                                            LIMIT 1)
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT cs.o_orderkey) AS order_count,
    AVG(cs.total_order_value) AS average_order_value,
    SUM(cs.total_supply_cost) AS total_supplier_cost,
    SUM(cs.parts_supplied) AS total_parts_supplied
FROM 
    CombinedStats cs
JOIN 
    supplier s ON cs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_cost DESC;
