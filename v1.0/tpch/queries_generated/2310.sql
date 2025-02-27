WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
), OrderDiscounts AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice - (o.o_totalprice * SUM(l.l_discount) OVER (PARTITION BY o.o_orderkey)) AS discounted_total,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
), CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name, 
    cr.nation_name,
    ss.s_name, 
    ss.total_available_qty,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(od.discounted_total) AS total_discounted_sales
FROM 
    SupplierSummary ss
LEFT JOIN 
    lineitem l ON ss.s_suppkey = l.l_suppkey
LEFT JOIN 
    OrderDiscounts od ON l.l_orderkey = od.o_orderkey
JOIN 
    CustomerRegions cr ON od.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem li ON o.o_orderkey = li.l_orderkey
        WHERE li.l_suppkey = ss.s_suppkey
    )
WHERE 
    od.discounted_total IS NOT NULL
GROUP BY 
    cr.region_name, 
    cr.nation_name, 
    ss.s_name, 
    ss.total_available_qty
HAVING 
    SUM(od.discounted_total) > 1000
ORDER BY 
    cr.region_name, 
    total_discounted_sales DESC;
