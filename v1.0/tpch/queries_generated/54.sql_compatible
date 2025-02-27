
WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ts.total_sales
    FROM 
        orders o
    JOIN 
        TotalSales ts ON o.o_orderkey = ts.l_orderkey
    WHERE 
        ts.total_sales > 10000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    pv.p_name,
    COALESCE(si.total_available, 0) AS available_quantity,
    COALESCE(si.avg_supply_cost, 0) AS average_cost,
    COUNT(DISTINCT h.o_orderkey) AS high_value_orders_count,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': $', ROUND(ts.total_sales, 2)), ', ') AS suppliers_sales_info
FROM 
    part pv
LEFT JOIN 
    PartSupplierInfo si ON pv.p_partkey = si.ps_partkey
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = pv.p_partkey 
        LIMIT 1
    )
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = si.ps_suppkey
LEFT JOIN 
    TotalSales ts ON ts.l_orderkey = h.o_orderkey
WHERE 
    pv.p_retailprice > 50
GROUP BY 
    pv.p_name, si.total_available, si.avg_supply_cost
ORDER BY 
    available_quantity DESC, pv.p_name ASC;
