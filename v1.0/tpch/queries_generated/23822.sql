WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipmode IN ('AIR', 'SHIP') 
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty,
    COALESCE(s.s_name, 'Unknown Supplier') AS Supplier_Name,
    COALESCE(rc.r_name, 'Unknown Region') AS Region_Name,
    CASE 
        WHEN SUM(COALESCE(hv.total_revenue, 0)) > 50000 THEN 'High Value'
        ELSE 'Regular Value' 
    END AS Order_Value_Category
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region rc ON n.n_regionkey = rc.r_regionkey
LEFT JOIN 
    HighValueOrders hv ON hv.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
WHERE 
    p.p_retailprice BETWEEN (SELECT MIN(p2.p_retailprice) FROM part p2) AND (SELECT MAX(p3.p_retailprice) FROM part p3 WHERE p3.p_mfgr != p.p_mfgr)
GROUP BY 
    p.p_partkey, p.p_name, ps.ps_availqty, s.s_name, rc.r_name
ORDER BY 
    p.p_partkey DESC, 
    Supplier_Name,
    Order_Value_Category DESC;
