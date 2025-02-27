WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_address, 
        c.c_phone, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_phone
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        p.p_name, 
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_availqty DESC) AS rank_within_part
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    r.s_name AS supplier_name,
    r.nation AS supplier_nation,
    c.c_name AS customer_name,
    c.c_phone AS customer_phone,
    pa.p_name AS part_name,
    s.ps_availqty AS available_quantity,
    COALESCE(co.total_spent, 0) AS customer_total_spent,
    r.rank_within_nation,
    pa.rank_within_part
FROM 
    RankedSuppliers r
JOIN 
    CustomerOrders co ON r.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = r.n_suppkey)
JOIN 
    SupplierPartAvailability pa ON r.s_suppkey = pa.ps_suppkey
JOIN 
    lineitem l ON l.l_suppkey = r.s_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    r.rank_within_nation <= 5 AND 
    pa.rank_within_part <= 3
ORDER BY 
    r.nation, r.rank_within_nation, co.customer_total_spent DESC;
