WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
CriticalOrders AS (
    SELECT 
        o.o_orderkey, 
        os.order_total,
        RANK() OVER (ORDER BY os.order_total DESC) AS order_rank
    FROM 
        OrderSummary os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    WHERE 
        os.order_total > (SELECT AVG(order_total) FROM OrderSummary)
)
SELECT 
    ss.s_name, 
    ss.part_count, 
    ss.total_supply_value, 
    co.order_total
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    CriticalOrders co ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                            FROM partsupp ps 
                                            JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                            WHERE l.l_orderkey IN (SELECT o_orderkey FROM CriticalOrders))
WHERE 
    ss.s_acctbal IS NOT NULL
ORDER BY 
    ss.total_supply_value DESC NULLS LAST;
