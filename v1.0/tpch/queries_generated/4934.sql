WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        CustomerOrderStats cos
    JOIN 
        customer c ON cos.c_custkey = c.c_custkey
    WHERE 
        cos.total_orders > 5 AND cos.avg_order_value > 1000
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        s.s_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cos.c_custkey) AS high_value_customers,
    SUM(ht.total_available) AS total_available_parts,
    AVG(ht.avg_supply_cost) AS average_supply_cost,
    MAX(p.p_retailprice) AS highest_part_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ht ON s.s_suppkey = ht.s_suppkey
LEFT JOIN 
    HighValueCustomers cos ON s.s_nationkey = cos.c_custkey
LEFT JOIN 
    PartSupplierDetails p ON s.s_suppkey = p.s_name
WHERE 
    r.r_name LIKE 'A%' OR r.r_comment IS NULL
GROUP BY 
    r.r_name
ORDER BY 
    high_value_customers DESC, total_available_parts DESC;
