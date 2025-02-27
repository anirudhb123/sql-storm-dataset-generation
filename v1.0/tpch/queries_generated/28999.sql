WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' | ', p.p_name) AS supplier_part_combo
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_id,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        CONCAT(c.c_name, ' | ', o.o_orderkey) AS customer_order_combo
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey
),
BenchmarkResults AS (
    SELECT 
        sp.supplier_name,
        sp.part_name,
        co.customer_name,
        co.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY co.customer_name ORDER BY co.total_revenue DESC) AS rank
    FROM 
        SupplierParts sp
    JOIN 
        CustomerOrders co ON sp.available_quantity > 0
)
SELECT 
    supplier_name,
    part_name,
    customer_name,
    total_revenue,
    rank
FROM 
    BenchmarkResults
WHERE 
    rank <= 5
ORDER BY 
    customer_name, total_revenue DESC;
