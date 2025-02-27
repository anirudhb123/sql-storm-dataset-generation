WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) OVER (PARTITION BY s.s_nationkey ORDER BY s.s_suppkey ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus LIKE 'F%' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey
),
SupplierPartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count,
        AVG(p.p_retailprice * ps.ps_availqty) AS avg_retail_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        AVG(p.p_retailprice * ps.ps_availqty) IS NOT NULL
),
FinalStats AS (
    SELECT 
        ns.n_name,
        COUNT(DISTINCT c.c_custkey) AS distinct_customers,
        SUM(s.total_supply_cost) AS total_supplier_cost,
        SUM(sp.avg_retail_value) AS total_average_retail_value
    FROM 
        nation ns
    LEFT JOIN 
        supplier s ON ns.n_nationkey = s.s_nationkey
    LEFT JOIN 
        CustomerOrderInfo c ON c.c_custkey IS NOT NULL
    LEFT JOIN 
        SupplierPartInfo sp ON s.s_suppkey = sp.p_partkey
    WHERE 
        ns.n_name NOT IN (SELECT DISTINCT n_name FROM nation WHERE n_nationkey IS NULL)
    GROUP BY 
        ns.n_name
)

SELECT 
    n.n_name,
    COALESCE(fs.distinct_customers, 0) AS customers_count,
    COALESCE(fs.total_supplier_cost, 0.00) AS total_cost,
    COALESCE(fs.total_average_retail_value, 0.00) AS avg_retail_value
FROM 
    nation n
LEFT JOIN 
    FinalStats fs ON n.n_nationkey = fs.n_nationkey
WHERE 
    n.r_regionkey IS NOT NULL
ORDER BY 
    n.n_name DESC NULLS LAST;
