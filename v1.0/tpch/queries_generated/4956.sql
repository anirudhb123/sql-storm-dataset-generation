WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
MediumOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_totalprice BETWEEN 10000 AND 50000 
        AND o.o_orderstatus = 'O'
),
HighValueLineitems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value_sum
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name, 
    rs.s_name, 
    rs.total_supply_cost,
    mo.o_orderkey,
    mo.o_totalprice,
    mo.o_orderdate,
    hvl.high_value_sum
FROM 
    RankedSupplier rs
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
JOIN 
    MediumOrders mo ON mo.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_suppkey = rs.s_suppkey
    )
LEFT JOIN 
    HighValueLineitems hvl ON hvl.l_orderkey = mo.o_orderkey
WHERE 
    rs.rank = 1
    AND (rs.total_supply_cost IS NOT NULL OR rs.s_name LIKE '%Supplier%')
ORDER BY 
    n.n_name, 
    rs.total_supply_cost DESC;
