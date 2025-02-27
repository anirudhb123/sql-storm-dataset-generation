WITH RecursiveCTE AS (
    SELECT 
        part.p_partkey, 
        part.p_name, 
        SUM(COALESCE(lineitem.l_extendedprice, 0) * (1 - lineitem.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY part.p_partkey ORDER BY SUM(COALESCE(lineitem.l_extendedprice, 0) * (1 - lineitem.l_discount)) DESC) AS revenue_rank
    FROM 
        part
    LEFT JOIN 
        lineitem ON part.p_partkey = lineitem.l_partkey
    GROUP BY 
        part.p_partkey, part.p_name
),
SupplierRevenue AS (
    SELECT 
        supplier.s_suppkey, 
        supplier.s_name,
        SUM(partsupp.ps_supplycost * partsupp.ps_availqty) AS total_supply_cost
    FROM 
        supplier
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY 
        supplier.s_suppkey, supplier.s_name
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        RANK() OVER (ORDER BY sr.total_supply_cost DESC) AS rank
    FROM 
        SupplierRevenue sr
),
NationSummary AS (
    SELECT 
        nation.n_name,
        COUNT(DISTINCT customer.c_custkey) AS total_customers,
        SUM(customer.c_acctbal) AS total_balance
    FROM 
        nation
    JOIN 
        customer ON nation.n_nationkey = customer.c_nationkey
    GROUP BY 
        nation.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.total_customers,
    ns.total_balance,
    tr.total_revenue,
    ts.s_name AS top_supplier_name
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RecursiveCTE tr ON tr.revenue_rank = 1
LEFT JOIN 
    TopSuppliers ts ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'UNITED STATES')
WHERE 
    (total_balance IS NOT NULL OR total_customers > 0)
    AND (total_revenue > (SELECT AVG(total_revenue) FROM RecursiveCTE) OR tr.p_partkey IS NULL)
ORDER BY 
    region_name, nation_name;
