WITH RECURSIVE OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
), CTE_Supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CTE_Nation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), Combined AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.total_lineitem_value,
        COALESCE(cs.supplier_value, 0) AS supplier_value,
        cn.supplier_count
    FROM 
        OrderDetails od
    LEFT JOIN 
        CTE_Supplier cs ON od.o_orderkey = cs.s_suppkey
    LEFT JOIN 
        CTE_Nation cn ON cs.s_suppkey = cn.supplier_count
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.total_lineitem_value,
    o.supplier_value,
    o.supplier_count,
    CASE 
        WHEN o.total_lineitem_value > 10000 THEN 'High Value Order'
        WHEN o.total_lineitem_value BETWEEN 5000 AND 10000 THEN 'Medium Value Order'
        ELSE 'Low Value Order'
    END AS order_value_category
FROM 
    Combined o
WHERE 
    (o.supplier_value IS NULL OR o.supplier_value <> 0)
    AND o.supplier_count IS NOT NULL
ORDER BY 
    o.o_orderdate DESC, o.total_lineitem_value DESC;
