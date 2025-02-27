WITH RECURSIVE CTE_SupplierCosts AS (
    SELECT 
        ps.suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    GROUP BY 
        ps.suppkey
),
RankedSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        COALESCE(c.total_cost, 0) AS supplier_cost,
        RANK() OVER (ORDER BY COALESCE(c.total_cost, 0) DESC, s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        CTE_SupplierCosts c ON s.s_suppkey = c.suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
Nations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS suppliers_count,
        SUM(CASE WHEN s.s_acctbal IS NULL THEN 1 ELSE 0 END) AS null_account_suppliers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    cs.order_count AS customer_order_count,
    cs.total_spent AS customer_total_spent,
    rs.s_name AS supplier_name,
    rs.supplier_cost,
    CASE 
        WHEN rs.rank <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_rank,
    n.suppliers_count,
    n.null_account_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    CustomerOrders cs ON cs.c_custkey IN (SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
WHERE 
    (cs.order_count > 0 OR n.null_account_suppliers > 0)
    AND rs.supplier_cost IS NOT NULL
ORDER BY 
    region_name, nation_name, customer_total_spent DESC, supplier_cost DESC;
