WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
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
        MAX(o.o_totalprice) AS max_order_price,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 10
)
SELECT 
    r.r_name,
    COALESCE(ts.supplier_count, 0) AS total_suppliers,
    COALESCE(c.order_count, 0) AS total_orders,
    r.total_supply_cost,
    hd.high_value,
    ROW_NUMBER() OVER (ORDER BY r.n_nationkey) AS row_num
FROM 
    region r
LEFT JOIN 
    TopNations ts ON r.r_regionkey = ts.n_nationkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = (SELECT c_custkey FROM CustomerOrders WHERE order_count ORDER BY order_count DESC LIMIT 1)
LEFT JOIN 
    (SELECT 
         o.o_orderkey, 
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value
     FROM 
         orders o
     JOIN 
         lineitem l ON o.o_orderkey = l.l_orderkey
     WHERE 
         l.l_returnflag = 'N'
     GROUP BY 
         o.o_orderkey
     HAVING 
         SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
    ) hd ON hd.o_orderkey IN (SELECT o_orderkey FROM HighValueOrders)
ORDER BY 
    r.r_name DESC
LIMIT 50;
