WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.*, 
        CASE 
            WHEN total_spent > 10000 THEN 'High Roller'
            WHEN total_spent <= 10000 THEN 'Regular'
            ELSE 'Undefined'
        END AS customer_status
    FROM 
        CustomerOrders c
    WHERE 
        order_count > 5
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalResults AS (
    SELECT 
        hvc.c_custkey,
        hvc.c_name,
        p.p_partkey,
        p.p_name,
        ps.s_suppkey,
        ps.s_name,
        COALESCE(ps.s_acctbal, 0) AS supplier_balance,
        p.total_supply_cost, 
        hvc.customer_status
    FROM 
        HighValueCustomers hvc
    CROSS JOIN 
        PartSupplierInfo p
    LEFT JOIN 
        RankedSuppliers ps ON ps.rank = 1 AND ps.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey)
    WHERE 
        hvc.customer_status = 'High Roller' 
        AND (p.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartSupplierInfo) OR hvc.total_spent IS NULL)
)
SELECT 
    DISTINCT f.c_custkey,
    f.c_name,
    f.p_partkey,
    f.p_name,
    f.s_suppkey,
    f.s_name,
    f.supplier_balance,
    f.total_supply_cost
FROM 
    FinalResults f
WHERE 
    f.supplier_balance IS NOT NULL
ORDER BY 
    f.c_custkey, f.p_partkey;
