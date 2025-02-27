WITH SupplierCost AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_order_value,
        ROW_NUMBER() OVER (ORDER BY co.total_order_value DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.o_custkey
    WHERE 
        co.total_order_value > 10000
),
RegionSupplierInfo AS (
    SELECT 
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    rsi.r_name,
    rsi.s_name,
    rsi.s_acctbal,
    hvc.c_name AS high_value_customer,
    hvc.total_order_value
FROM 
    RegionSupplierInfo rsi
LEFT JOIN 
    HighValueCustomers hvc ON rsi.s_suppkey = (SELECT ps.ps_suppkey 
                                                 FROM partsupp ps 
                                                 WHERE ps.ps_availqty > 50 
                                                 ORDER BY ps.ps_supplycost DESC 
                                                 LIMIT 1)
WHERE 
    (rsi.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    ) OR hvc.rank <= 10)
ORDER BY 
    rsi.r_name, rsi.s_name;
