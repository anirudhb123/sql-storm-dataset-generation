WITH SuppliersWithCost AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey, 
        s.s_name, 
        s.s_address, 
        swc.total_supplycost
    FROM 
        supplier s
    JOIN 
        SuppliersWithCost swc ON s.s_suppkey = swc.s_suppkey
    WHERE 
        swc.rank <= 3
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalBenchmark AS (
    SELECT 
        n.n_name AS nation_name,
        COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
        coi.c_name AS customer_name,
        total_spent,
        order_count,
        total_supplycost
    FROM 
        nation n
    LEFT JOIN 
        TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
    FULL OUTER JOIN 
        CustomerOrderInfo coi ON ts.s_name IS NOT NULL AND coi.total_spent IS NOT NULL
    WHERE 
        (coi.total_spent > 1000 OR ts.total_supplycost IS NULL)
    ORDER BY 
        nation_name, total_supplycost DESC, total_spent DESC
)
SELECT 
    nation_name,
    supplier_name,
    customer_name,
    total_spent,
    order_count,
    total_supplycost
FROM 
    FinalBenchmark
WHERE 
    total_spent IS NOT NULL OR total_supplycost IS NOT NULL
ORDER BY 
    nation_name, customer_name;
