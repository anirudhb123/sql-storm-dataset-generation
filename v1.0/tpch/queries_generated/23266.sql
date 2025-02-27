WITH RankedOrders AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_orderdate, 
        o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM 
        orders
),
AggregatedSupplierCosts AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        partsupp ps ON ps.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_supplycost = (
            SELECT MAX(ps_supplycost) FROM partsupp WHERE ps_partkey IN (SELECT ps_partkey FROM AggregatedSupplierCosts)
        ) LIMIT 1)
    LEFT JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, n.n_name, s.s_name
    HAVING 
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) > 0
),
OrderSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS active_customers,
        SUM(od.o_totalprice) AS revenue,
        SQUARE(SUM(od.o_totalprice)) AS revenue_square
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    JOIN 
        RankedOrders ro ON ro.o_custkey = c.c_custkey
    JOIN 
        orders od ON od.o_custkey = c.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    cd.c_custkey,
    cd.c_name,
    cd.c_acctbal,
    cs.nation_name,
    cs.supplier_name,
    os.revenue,
    os.active_customers,
    os.revenue_square
FROM 
    CustomerDetails cd
JOIN 
    (SELECT r_name, SUM(revenue) AS total_revenue FROM OrderSummary GROUP BY r_name) os ON os.active_customers > 10
JOIN 
    (SELECT n.n_name, COUNT(s.s_suppkey) AS supplier_count FROM supplier s 
     JOIN nation n ON n.n_nationkey = s.s_nationkey 
     GROUP BY n.n_name) cs ON cd.nation_name = cs.n_name
WHERE 
    cd.c_acctbal IS NOT NULL AND cd.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
ORDER BY 
    cd.c_acctbal DESC, os.revenue DESC;
