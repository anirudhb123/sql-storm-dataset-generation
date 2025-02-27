WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate <= DATE '2022-12-31'
), 
SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(ss.total_supply_cost) AS average_supplier_cost
FROM 
    RankedOrders o
JOIN 
    nation n ON n.n_nationkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        WHERE c.c_custkey = o.o_custkey
    )
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    SupplierSummary ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey = o.o_orderkey
    )
WHERE 
    o.order_rank <= 3
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC, r.r_name;
