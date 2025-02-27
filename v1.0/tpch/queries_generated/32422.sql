WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
), 
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RankedSuppliers AS (
    SELECT 
        s.*, 
        CASE 
            WHEN s.total_sales > 50000 THEN 'High'
            WHEN s.total_sales BETWEEN 20000 AND 50000 THEN 'Medium'
            ELSE 'Low'
        END AS supply_rank
    FROM 
        SupplierSales s
    WHERE 
        s.total_sales IS NOT NULL
), 
FilteredCustomerSales AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent
    FROM 
        CustomerSales cs
    WHERE 
        cs.rn = 1
)

SELECT 
    cs.c_name AS high_spender,
    cs.total_spent AS total_spent,
    ps.p_name AS part_name,
    ps.avg_supply_cost,
    ss.total_sales AS supplier_sales,
    rs.supply_rank
FROM 
    FilteredCustomerSales cs
JOIN 
    PartStatistics ps ON ps.rank <= 10
LEFT JOIN 
    RankedSuppliers rs ON rs.supply_rank = 'High'
LEFT JOIN 
    SupplierSales ss ON ss.order_count > 5
WHERE 
    ps.total_available > 100
ORDER BY 
    cs.total_spent DESC, ps.avg_supply_cost;
