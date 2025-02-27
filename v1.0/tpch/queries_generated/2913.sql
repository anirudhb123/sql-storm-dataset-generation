WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -12, GETDATE())
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_brand,
        p.p_size,
        COALESCE(pa.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(pa.supplier_count, 0) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplierAggregates pa ON p.p_partkey = pa.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(oi.o_totalprice) AS total_order_value,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_returned_quantity,
    STRING_AGG(DISTINCT CONCAT(p.p_name, '(', p.p_size, ')'), ', ') AS products_sold
FROM 
    RankedOrders oi
JOIN 
    customer c ON oi.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON oi.o_orderkey = l.l_orderkey
JOIN 
    PartDetails p ON l.l_partkey = p.p_partkey
WHERE 
    oi.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = oi.o_orderstatus)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 100 AND AVG(p.total_supply_cost) > 2000.00
ORDER BY 
    total_order_value DESC, region_name;
