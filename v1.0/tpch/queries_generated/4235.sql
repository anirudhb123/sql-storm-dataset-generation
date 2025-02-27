WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        SupplierStats s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM SupplierStats)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_after_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    ps.s_name AS supplier_name,
    cs.c_name AS customer_name,
    os.o_orderkey,
    os.total_after_discount,
    (SELECT COUNT(*) 
     FROM lineitem l 
     WHERE l.l_orderkey = os.o_orderkey AND l.l_returnflag = 'R') AS return_count
FROM 
    HighValueSuppliers ps
JOIN 
    CustomerStats cs ON cs.order_count > 5
JOIN 
    OrderSummary os ON os.total_after_discount > 1000
WHERE 
    ps.part_count > 10
ORDER BY 
    ps.s_name, cs.c_name;
