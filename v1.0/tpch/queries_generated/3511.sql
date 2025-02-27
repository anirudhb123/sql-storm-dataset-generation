WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(SUM(to.total_sales), 0) AS total_ordered_sales,
    COALESCE(MAX(ps.supplier_count), 0) AS max_suppliers,
    COALESCE(AVG(ps.avg_supply_cost), 0) AS average_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedOrders to ON r.r_name LIKE '%' || to.o_orderdate || '%' 
LEFT JOIN 
    PartSupplierStats ps ON ps.p_partkey IN (
        SELECT 
            DISTINCT l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderstatus = 'F' 
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_ordered_sales DESC
LIMIT 10;
