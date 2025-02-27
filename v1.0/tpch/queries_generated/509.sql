WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'C'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    p.p_name AS part_name,
    p.total_available_qty,
    p.p_retailprice,
    COALESCE(cd.order_count, 0) AS customer_order_count,
    COALESCE(cd.total_spent, 0) AS customer_total_spent,
    ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY p.total_available_qty DESC) AS rank_within_supplier
FROM 
    SupplierDetails s
JOIN 
    PartDetails p ON s.available_parts > 0
LEFT JOIN 
    CustomerOrders cd ON cd.order_count > 0
ORDER BY 
    s.s_name, cd.total_spent DESC, p.total_available_qty DESC;
