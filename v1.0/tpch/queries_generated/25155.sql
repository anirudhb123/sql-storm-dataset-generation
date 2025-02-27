WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        s.s_name AS supplier_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(p.p_name, ' from ', s.s_name) AS detail_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        MIN(o.o_orderdate) AS first_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    psi.p_partkey,
    psi.p_name,
    psi.supplier_name,
    psi.ps_availqty,
    psi.ps_supplycost,
    cinfo.c_custkey,
    cinfo.c_name,
    cinfo.orders_count,
    cinfo.total_spent,
    psi.comment_length,
    psi.detail_info
FROM 
    PartSupplierInfo psi
JOIN 
    CustomerOrderInfo cinfo ON psi.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    psi.comment_length DESC, cinfo.total_spent DESC
LIMIT 50;
