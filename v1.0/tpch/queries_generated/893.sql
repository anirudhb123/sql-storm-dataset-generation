WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        MAX(o.o_totalprice) AS highest_order_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        *
    FROM 
        SupplierDetails
    WHERE 
        rn <= 3
)
SELECT 
    r.r_name,
    TS.s_name AS supplier_name,
    O.o_orderkey,
    O.net_revenue,
    O.highest_order_price
FROM 
    region r
LEFT OUTER JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT OUTER JOIN 
    TopSuppliers TS ON s.s_suppkey = TS.s_suppkey
JOIN 
    OrderStats O ON O.o_orderkey IN (SELECT DISTINCT o_orderkey FROM orders WHERE o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey))
WHERE 
    TS.total_supply_cost IS NOT NULL
    AND (O.net_revenue IS NOT NULL OR O.highest_order_price > 1000)
ORDER BY 
    r.r_name, O.net_revenue DESC;
