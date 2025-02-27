
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS rnk,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    HVP.p_partkey,
    HVP.p_name,
    HVP.p_retailprice,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    COALESCE(RS.s_acctbal, 0) AS supplier_acct_balance,
    RO.o_orderkey,
    RO.o_totalprice,
    RO.line_item_count
FROM 
    HighValueParts HVP
FULL OUTER JOIN 
    RankedSuppliers RS ON HVP.p_partkey = RS.s_suppkey
LEFT JOIN 
    RecentOrders RO ON RS.s_suppkey = RO.o_orderkey
WHERE 
    (HVP.p_retailprice > 100 OR HVP.p_name LIKE '%special%')
    AND COALESCE(RS.rn, 0) <= 5
ORDER BY 
    HVP.p_partkey, RS.s_acctbal DESC, RO.o_totalprice DESC
LIMIT 10 OFFSET 5;
