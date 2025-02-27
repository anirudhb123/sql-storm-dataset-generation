
WITH SupplierDetails AS (
    SELECT 
        s.s_name,
        CONCAT(s.s_address, ', ', n.n_name) AS full_address,
        s.s_phone,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    sd.s_name,
    sd.full_address,
    sd.s_phone,
    sd.s_acctbal,
    pd.unique_suppliers,
    pd.total_avail_qty,
    co.total_orders,
    co.total_spent,
    co.last_order_date
FROM 
    SupplierDetails sd
LEFT JOIN 
    PartSuppliers pd ON pd.ps_partkey = (SELECT p.p_partkey FROM part p ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    CustomerOrders co ON co.c_name = (SELECT c.c_name FROM customer c ORDER BY RANDOM() LIMIT 1)
WHERE 
    sd.comment_length > 100
ORDER BY 
    sd.s_acctbal DESC, 
    co.total_spent DESC
LIMIT 10;
