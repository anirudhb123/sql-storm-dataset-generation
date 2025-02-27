
WITH SeasonalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(MONTH FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, EXTRACT(MONTH FROM o.o_orderdate)
),
TopSales AS (
    SELECT 
        ss.o_orderkey,
        ss.net_sales,
        ss.order_count
    FROM 
        SeasonalSales ss
    WHERE 
        ss.sales_rank <= 10
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    t.o_orderkey,
    t.net_sales,
    t.order_count,
    COALESCE(si.total_supply_cost, 0) AS total_supply_cost,
    si.supplier_count,
    CASE 
        WHEN t.net_sales IS NOT NULL AND si.total_supply_cost IS NOT NULL THEN (t.net_sales - si.total_supply_cost) / NULLIF(t.net_sales, 0)
        ELSE NULL
    END AS profit_margin
FROM 
    TopSales t
LEFT JOIN 
    SupplierInfo si ON si.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = t.o_orderkey)
WHERE 
    (t.order_count > 5 OR si.supplier_count > 2) AND
    (t.net_sales > 1000 OR si.total_supply_cost IS NOT NULL)
ORDER BY 
    profit_margin DESC, t.net_sales DESC;
