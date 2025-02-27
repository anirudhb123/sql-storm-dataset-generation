WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_account_balance,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), 
PartSupplierSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ns.n_name,
    ps.p_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
    ns.total_account_balance,
    ns.total_customers,
    MAX(CASE WHEN ss.sales_rank = 1 THEN ss.total_sales END) AS max_order_value
FROM 
    NationSales ns
LEFT JOIN 
    PartSupplierSales ps ON ns.total_account_balance > 100000
LEFT JOIN 
    SalesCTE ss ON ns.n_nationkey = ss.o_orderkey
WHERE 
    ns.total_customers > 0
GROUP BY 
    ns.n_name, ps.p_name, ns.total_account_balance, ns.total_customers
ORDER BY 
    ns.n_name, ps.p_name;
