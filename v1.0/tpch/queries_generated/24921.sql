WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, CURRENT_DATE) OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS num_customers,
        AVG(c.c_acctbal) AS avg_balance
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(ps.ps_supplycost) AS max_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    n.n_name,
    r.total_spent,
    n.num_customers,
    n.avg_balance,
    p.supplier_names,
    COALESCE(CASE WHEN rc.rank_within_nation <= 5 THEN 'Top 5 Customers' ELSE 'Others' END, 'No Customers') AS customer_category
FROM 
    NationSummary n
LEFT JOIN 
    RankedCustomers rc ON n.n_nationkey = rc.c_nationkey
LEFT JOIN 
    PartSupplierDetails p ON p.ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand = 'BrandX')
WHERE 
    n.num_customers > 0
  AND 
    (n.avg_balance IS NOT NULL OR n.num_customers > 10)
ORDER BY 
    n.n_name, r.total_spent DESC NULLS LAST;
