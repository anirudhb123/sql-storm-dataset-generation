WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P') 
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(a.total_avail_qty, 0) AS available_quantity,
    COALESCE(s.avg_supply_cost, 0.00) AS average_supply_cost,
    ROUND((p.p_retailprice * COALESCE(a.total_avail_qty, 0)), 2) AS potential_revenue,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    AvailableParts a ON p.p_partkey = a.ps_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
    AND EXISTS (SELECT 1 FROM RankedOrders ro WHERE ro.o_orderkey IN 
        (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
    AND (p.p_brand LIKE 'Brand%')
    AND (s.s_suppkey IN (SELECT s2.s_suppkey FROM TopSuppliers s2 WHERE s2.supplier_rank <= 5))
ORDER BY 
    potential_revenue DESC,
    p.p_name
LIMIT 50;
