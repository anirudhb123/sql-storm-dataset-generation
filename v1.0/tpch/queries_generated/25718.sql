WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Available Quantity: ', ps.ps_availqty, 
               ', Supply Cost: ', FORMAT(ps.ps_supplycost, 2), ', Comment: ', ps.ps_comment) AS details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        CONCAT('Customer: ', c.c_name, ', Order Total: ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2), 
               ', Order Key: ', o.o_orderkey) AS order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
    HAVING 
        total_order_value > 1000
)
SELECT 
    psi.details,
    coi.order_details
FROM 
    PartSupplierInfo psi
JOIN 
    CustomerOrderInfo coi ON psi.ps_availqty > 10
ORDER BY 
    psi.p_partkey, coi.total_order_value DESC;
