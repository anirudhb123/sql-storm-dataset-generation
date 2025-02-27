WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_info
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(cs.total_spent, 0.00) AS total_spent_by_customer,
    ps.total_available_qty,
    ps.total_supply_cost,
    ps.supplier_info
FROM 
    part p
LEFT JOIN 
    CustomerOrderStats cs ON cs.c_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        ORDER BY 
            c.c_acctbal DESC 
        LIMIT 1
    )
LEFT JOIN 
    PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    p.p_name ASC;
