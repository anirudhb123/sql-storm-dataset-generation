WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        c.c_phone,
        c.c_acctbal,
        c.c_comment,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_nationkey, c.c_phone, c.c_acctbal, c.c_comment
),
PartOrderDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_extended_price,
        MAX(l.l_discount) AS max_discount,
        MIN(l.l_tax) AS min_tax
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    sd.s_name AS supplier_name,
    cd.c_name AS customer_name,
    pod.p_name AS part_name,
    pod.total_quantity,
    pod.avg_extended_price,
    sd.total_parts,
    cd.total_spent,
    cd.total_orders
FROM 
    SupplierDetails sd
JOIN 
    CustomerDetails cd ON sd.s_nationkey = cd.c_nationkey
JOIN 
    PartOrderDetails pod ON sd.total_parts > 10 AND cd.total_spent > 1000
ORDER BY 
    cd.total_spent DESC, pod.total_quantity DESC;
