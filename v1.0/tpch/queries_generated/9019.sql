WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND 
        o.o_orderdate <= '2022-12-31'
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31' AND 
        l.l_returnflag = 'R'
    GROUP BY 
        l.l_orderkey
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name AS customer_name,
    COALESCE(fli.total_revenue, 0) AS total_revenue,
    si.supplier_name,
    si.total_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
JOIN 
    SupplierInfo si ON si.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost < 100)
WHERE 
    ro.rnk = 1
ORDER BY 
    ro.o_orderdate DESC, ro.o_orderkey;
