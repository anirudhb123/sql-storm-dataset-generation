WITH RECURSIVE PriceTrends AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
    UNION ALL
    SELECT 
        pt.p_partkey,
        pt.p_name,
        pt.p_retailprice * 0.95 AS p_retailprice,
        rn + 1
    FROM 
        PriceTrends pt
    WHERE 
        pt.rn < 5
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) OVER (PARTITION BY s.s_nationkey) AS avg_nation_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        (COALESCE(co.total_orders, 0) > 10 OR c.c_acctbal > 5000) AND
        c.c_mktsegment IN (SELECT DISTINCT c_mktsegment FROM customer WHERE c_acctbal IS NOT NULL)
)
SELECT 
    hvc.c_name,
    hvc.total_orders,
    hvc.total_spent,
    ps.part_count,
    ps.total_supply_cost,
    pt.p_name,
    pt.p_retailprice
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    SupplierStats ps ON hvc.total_orders > 0
INNER JOIN 
    PriceTrends pt ON hvc.total_orders < 5
ORDER BY 
    hvc.total_spent DESC,
    hvc.c_name ASC
LIMIT 100;
