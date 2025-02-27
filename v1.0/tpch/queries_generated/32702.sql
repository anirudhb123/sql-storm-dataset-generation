WITH RECURSIVE CostAnalysis AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ps_availqty * ps_supplycost AS total_cost
    FROM partsupp
    WHERE ps_availqty > 0
    UNION ALL
    SELECT 
        p.ps_partkey,
        p.ps_suppkey,
        p.ps_availqty - 1,
        p.ps_supplycost,
        (p.ps_availqty - 1) * p.ps_supplycost AS total_cost
    FROM partsupp p
    JOIN CostAnalysis ca ON p.ps_partkey = ca.ps_partkey
    WHERE ca.ps_availqty > 1
),
SupplierDetail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ca.total_cost) AS total_supplier_cost
    FROM supplier s
    JOIN CostAnalysis ca ON s.s_suppkey = ca.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_purchases,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supplier_cost
    FROM SupplierDetail sd
    WHERE sd.total_supplier_cost > (SELECT AVG(total_supplier_cost) FROM SupplierDetail)
)
SELECT 
    cp.c_name,
    cp.total_purchases,
    fs.s_name,
    fs.total_supplier_cost,
    COALESCE(cp.total_purchases - fs.total_supplier_cost, 0) AS profit_margin
FROM CustomerPurchases cp
FULL OUTER JOIN FilteredSuppliers fs ON cp.rnk = fs.s_suppkey
WHERE cp.total_purchases IS NOT NULL OR fs.total_supplier_cost IS NOT NULL
ORDER BY profit_margin DESC, cp.total_purchases DESC;
