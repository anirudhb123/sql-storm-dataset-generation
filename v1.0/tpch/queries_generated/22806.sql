WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty,
        AVG(COALESCE(ps.ps_supplycost, 0)) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.supplier_count,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    NULLIF(co.avg_order_value, 0) AS avg_order_value,
    CASE WHEN co.order_count > 0 THEN 'Customer Active' ELSE 'No Orders' END AS customer_status,
    string_agg(DISTINCT CONCAT('Supplier: ', s.s_name, ' - Balance: ', s.s_acctbal) 
    ORDER BY s.s_acctbal DESC) AS supplier_info
FROM 
    PartStats ps
LEFT JOIN 
    RankedSuppliers s ON ps.supplier_count > 0
LEFT JOIN 
    CustomerOrders co ON ps.p_partkey = co.c_custkey 
WHERE 
    ps.avg_supply_cost > (SELECT AVG(ps2.ps_supplycost) 
                           FROM partsupp ps2)
    AND ps.total_avail_qty IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, ps.supplier_count, ps.total_avail_qty, ps.avg_supply_cost, co.order_count, co.total_spent
ORDER BY 
    ps.total_avail_qty DESC, avg_order_value NULLS LAST;
