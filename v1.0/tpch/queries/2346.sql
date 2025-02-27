WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), SupplierParts AS (
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
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(sp.s_name, 'Unknown Supplier') AS supplier_name,
    hpp.p_name AS high_value_part,
    hpp.total_revenue,
    sp.total_supply_cost,
    DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierParts sp ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#0001') LIMIT 1)
JOIN 
    HighValueParts hpp ON hpp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1)
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
ORDER BY 
    o.o_orderdate DESC, total_revenue ASC;