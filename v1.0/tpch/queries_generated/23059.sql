WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
CriticalParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 100
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS order_value,
        COUNT(li.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
), 
SupplierInRegion AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_name,
    CASE 
        WHEN rs.rank <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_status,
    SUM(od.order_value) AS total_order_value,
    sr.supplier_count AS active_suppliers,
    NULLIF(MAX(od.line_item_count), 0) AS non_zero_line_items,
    STRING_AGG(DISTINCT rs.s_name, ', ') WITHIN GROUP (ORDER BY rs.s_name) AS supplier_names
FROM 
    CriticalParts p
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        AND ps.ps_availqty > 0
    )
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem li ON o.o_orderkey = li.l_orderkey 
        WHERE li.l_partkey = p.p_partkey 
        AND li.l_linenumber IS NOT NULL
    )
JOIN 
    SupplierInRegion sr ON sr.r_name = (SELECT r.r_name FROM region r LIMIT 1) 
GROUP BY 
    p.p_name, rs.rank, sr.supplier_count
HAVING 
    SUM(od.order_value) > 0
ORDER BY 
    total_order_value DESC, supplier_status;
