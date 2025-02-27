WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) as part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent,
        COUNT(o.o_orderkey) as order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    hvc.c_name AS customer_name,
    p.p_name AS part_name,
    ps.ps_supplycost AS supply_cost,
    ps.ps_availqty AS available_quantity,
    ro.o_orderkey AS recent_order,
    ro.o_orderdate AS order_date,
    ro.o_totalprice AS order_value
FROM 
    HighValueCustomers hvc
JOIN 
    RankedOrders ro ON hvc.c_custkey = ro.o_orderkey  -- Assuming orders map to customers by some key
JOIN 
    PartSupplier ps ON ps.ps_partkey IN (SELECT ps_partkey FROM orders)
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM PartSupplier) 
    AND ro.o_orderdate = (SELECT MAX(o_orderdate) FROM orders o WHERE o.o_custkey = hvc.c_custkey)
ORDER BY 
    hvc.c_name ASC, ro.o_totalprice DESC;
