WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name
),
SupplierCTE AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        p.p_partkey, s.s_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_name,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
    HAVING 
        COUNT(*) > 5
)
SELECT 
    s.s_name,
    COALESCE(sct.revenue, 0) AS total_revenue,
    COALESCE(ss.total_cost, 0) AS total_cost,
    CASE 
        WHEN s.s_name IS NOT NULL THEN 
            'Supplier exists'
        ELSE 
            'Supplier not found'
    END AS supplier_status
FROM 
    FilteredSuppliers s
LEFT JOIN 
    SalesCTE sct ON s.s_name = sct.c_name
LEFT JOIN 
    SupplierCTE ss ON s.s_name = (SELECT s_name FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_retailprice > 100)))
WHERE 
    ss.total_cost IS NOT NULL
    OR sct.revenue IS NOT NULL
ORDER BY 
    total_revenue DESC, total_cost DESC;
