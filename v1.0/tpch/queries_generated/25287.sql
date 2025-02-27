WITH PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        CONCAT('Brand: ', p.p_brand, ', Name: ', p.p_name) AS full_description,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' (Supplier ID: ', s.s_suppkey, ')') AS supplier_info,
        MAX(s.s_acctbal) AS highest_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS highest_order_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.full_description,
    sd.supplier_info,
    cd.c_name AS customer_name,
    cd.order_count,
    cd.highest_order_total,
    ps.total_available_quantity,
    ps.total_supply_cost
FROM 
    PartSummary ps
JOIN 
    SupplierDetails sd ON ps.p_partkey = (
        SELECT ps1.ps_partkey 
        FROM partsupp ps1 
        WHERE ps1.ps_availqty = (
            SELECT MAX(ps2.ps_availqty) 
            FROM partsupp ps2 
            WHERE ps2.ps_partkey = ps.p_partkey)
    )
JOIN 
    CustomerOrders cd ON cd.order_count > 0
ORDER BY 
    ps.total_supply_cost DESC, sd.highest_account_balance DESC;
