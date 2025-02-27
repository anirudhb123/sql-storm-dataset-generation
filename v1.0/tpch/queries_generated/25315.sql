WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM part p
    WHERE p.p_size > 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(li.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    sd.s_name AS Supplier_Name,
    pd.p_name AS Part_Name,
    od.o_orderkey AS Order_Key,
    od.o_orderdate AS Order_Date,
    od.o_totalprice AS Total_Price,
    sd.total_supply_value AS Total_Supply_Value,
    pd.short_comment AS Part_Comment,
    sd.part_count AS Total_Parts_Supplied
FROM SupplierDetails sd
JOIN PartDetails pd ON sd.part_count > 0
JOIN OrderDetails od ON od.line_item_count > 0
WHERE sd.total_supply_value > 10000
ORDER BY sd.total_supply_value DESC, od.o_totalprice ASC;
