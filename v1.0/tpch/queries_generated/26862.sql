WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        s.s_name AS supplier_name,
        CONCAT(s.s_address, ', ', s.s_phone) AS contact_info,
        SUBSTRING(s.s_comment, 1, 50) AS supplier_comment,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), CustomerStatistics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), OrderLineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(l.l_linenumber) AS line_items_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    psi.p_name,
    psi.p_brand,
    psi.supplier_name,
    psi.contact_info,
    psi.supplier_comment,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ols.total_lineitem_value,
    ols.line_items_count
FROM 
    PartSupplierInfo psi
JOIN 
    CustomerStatistics cs ON psi.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN orders o ON ps.ps_supplycost = o.o_totalprice
        WHERE o.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l)
    )
JOIN 
    OrderLineItemSummary ols ON ols.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_name = cs.c_name
    )
ORDER BY 
    psi.p_name, cs.total_spent DESC;
