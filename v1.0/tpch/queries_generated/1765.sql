WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
CustomerSupplierInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey 
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    GROUP BY 
        c.c_custkey, c.c_name, s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name 
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    csi.c_custkey,
    csi.c_name,
    csi.s_suppkey,
    csi.s_name,
    COALESCE(csi.total_orders, 0) AS total_orders,
    hvs.total_supply_cost,
    roa.o_totalprice,
    CASE 
        WHEN roa.order_rank = 1 THEN 'Highest'
        WHEN roa.order_rank <= 5 THEN 'Top 5'
        ELSE 'Regular'
    END AS order_value_classification
FROM 
    CustomerSupplierInfo csi
LEFT JOIN 
    HighValueSuppliers hvs ON csi.s_suppkey = hvs.s_suppkey
LEFT JOIN 
    RankedOrders roa ON csi.total_orders > 0 AND roa.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_custkey = csi.c_custkey)
WHERE 
    csi.s_acctbal IS NOT NULL
ORDER BY 
    hvs.total_supply_cost DESC NULLS LAST,
    csi.c_name ASC;
