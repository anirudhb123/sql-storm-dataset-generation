
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_clerk,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.total_supply_value,
        RANK() OVER (ORDER BY si.total_supply_value DESC) AS supply_rank
    FROM 
        SupplierInfo si
    WHERE 
        si.total_parts_supplied > 0
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue,
        COUNT(*) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    ro.o_clerk,
    COALESCE(MAX(l.total_line_revenue), 0) AS max_line_revenue,
    COALESCE(MAX(ts.total_supply_value), 0) AS max_supply_value,
    CASE 
        WHEN ro.o_totalprice > (SELECT AVG(o2.o_totalprice) 
                                FROM orders o2 
                                WHERE o2.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31')
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_category
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_partkey IN 
                                               (SELECT l.l_partkey 
                                                FROM lineitem l 
                                                WHERE l.l_orderkey = ro.o_orderkey)
                                         LIMIT 1) 
WHERE 
    ro.order_rank <= 10
GROUP BY 
    ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus, ro.o_clerk
ORDER BY 
    ro.o_orderdate DESC;
