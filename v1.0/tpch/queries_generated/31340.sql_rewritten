WITH RECURSIVE CategorySales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
)
SELECT 
    cs.p_name,
    cs.total_sales,
    ss.s_name AS supplier_name,
    ss.supplied_parts,
    hvo.o_orderkey,
    hvo.total_lineitem_value,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Exist' 
    END AS sales_status
FROM 
    CategorySales cs
FULL OUTER JOIN 
    SupplierSales ss ON cs.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = ss.total_supply_cost LIMIT 1)
LEFT JOIN 
    HighValueOrders hvo ON hvo.total_lineitem_value = (SELECT MAX(total_lineitem_value) FROM HighValueOrders)
WHERE 
    cs.rank = 1 OR ss.supplied_parts > 10
ORDER BY 
    cs.total_sales DESC NULLS LAST, 
    ss.supplied_parts DESC;