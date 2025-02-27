WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal 
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank = 1
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus <> 'F' -- Exclude finished orders
    GROUP BY 
        o.o_orderkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey, 
        n.n_name 
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)

SELECT 
    ps.ps_partkey,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT os.o_orderkey) AS order_count,
    COALESCE(TS.s_acctbal, 0) AS top_supplier_acctbal,
    CN.n_name AS customer_nation
FROM 
    partsupp ps
LEFT JOIN 
    TopSuppliers TS ON ps.ps_suppkey = TS.s_suppkey
LEFT JOIN 
    OrderSummary os ON ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_orderstatus <> 'F'
    )
LEFT JOIN 
    CustomerNation CN ON os.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey
    )
GROUP BY 
    ps.ps_partkey, CN.n_name, TS.s_acctbal
HAVING 
    total_available > 0 
ORDER BY 
    total_available DESC;
