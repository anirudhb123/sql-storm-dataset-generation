WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        s.s_name AS supplier_name,
        s.s_address,
        s.s_phone,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        CONCAT(p.p_name, ' (', p.p_brand, ') - ', p.p_type) AS part_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_comment,
        CONCAT(c.c_name, ' - Order No: ', o.o_orderkey) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
ExtendedDetails AS (
    SELECT 
        ps.part_description,
        cs.customer_order_info,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT cs.o_orderkey) AS order_count
    FROM 
        PartSupplierDetails ps
    JOIN 
        CustomerOrderDetails cs ON ps.p_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (
                SELECT o.o_orderkey 
                FROM orders o 
                JOIN customer c ON o.o_custkey = c.c_custkey 
                WHERE c.c_name LIKE 'Customer%'
            )
        )
    GROUP BY 
        ps.part_description, cs.customer_order_info
)
SELECT 
    part_description, 
    customer_order_info, 
    total_supply_cost, 
    order_count 
FROM 
    ExtendedDetails 
ORDER BY 
    total_supply_cost DESC, 
    order_count DESC;
