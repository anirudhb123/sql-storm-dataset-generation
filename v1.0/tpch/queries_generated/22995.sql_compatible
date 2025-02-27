
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
            WHERE s2.s_nationkey = s.s_nationkey
        )
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER(PARTITION BY p.p_partkey) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice >= 100 AND
        p.p_type IN ('type1', 'type2') 
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        AVG(l.l_discount) AS avg_discount,
        COUNT(l.l_orderkey) AS total_lines,
        MAX(l.l_returnflag) AS return_flag
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    p.p_name,
    s.s_name,
    od.order_total,
    CASE 
        WHEN od.avg_discount > 0.1 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    COUNT(CASE WHEN rs.rank_acctbal = 1 THEN 1 END) AS top_supplier_count,
    COALESCE(od.return_flag, 'N/A') AS return_status
FROM 
    HighValueParts p
JOIN 
    RankedSuppliers rs ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IS NOT NULL LIMIT 1)
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey LIMIT 1) LIMIT 1)
GROUP BY 
    p.p_name, s.s_name, od.order_total, od.avg_discount, od.total_lines, od.return_flag
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY 
    discount_category DESC, order_total DESC
LIMIT 10;
