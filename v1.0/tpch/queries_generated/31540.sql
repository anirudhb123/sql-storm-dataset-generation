WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sp.s_comment, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_suppkey = (sh.s_suppkey - 1)  -- Assuming a hierarchical relationship for demo purposes
    WHERE sp.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalSales AS (
    SELECT 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(ts.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ts.total_sales, 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        TotalSales ts ON c.c_custkey = ts.o_custkey
),
PartSuppliers AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        part_name, 
        total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS cost_rank
    FROM 
        PartSuppliers
)
SELECT 
    cs.c_name, 
    cs.total_sales, 
    ps.part_name, 
    ps.total_supply_cost
FROM 
    CustomerSales cs
LEFT JOIN 
    TopParts ps ON cs.sales_rank = ps.cost_rank
WHERE 
    cs.total_sales > 1000 OR ps.total_supply_cost IS NULL
ORDER BY 
    cs.total_sales DESC, 
    ps.total_supply_cost ASC
