WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability: ', CAST(ps.ps_availqty AS VARCHAR), 
               ' at a cost of ', FORMAT(ps.ps_supplycost, 'C', 'en-US')) AS supplier_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrder AS (
    SELECT 
        c.c_name AS customer_name, 
        o.o_orderkey AS order_key, 
        o.o_orderdate AS order_date, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        CONCAT(c.c_name, ' placed order #', CAST(o.o_orderkey AS VARCHAR), 
               ' on ', FORMAT(o.o_orderdate, 'MMMM dd, yyyy'), 
               ' totaling ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 'C', 'en-US')) AS order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    COALESCE(sp.available_quantity, 0) AS available_quantity,
    COALESCE(sp.supply_cost, 0) AS supply_cost,
    co.customer_name,
    co.order_key,
    co.order_date,
    co.total_price,
    CONCAT(sp.supplier_details, ' | ', co.order_details) AS full_details
FROM 
    SupplierParts sp
FULL OUTER JOIN 
    CustomerOrder co ON sp.supplier_name IS NOT NULL OR co.customer_name IS NOT NULL
ORDER BY 
    sp.supplier_name, co.order_date;
