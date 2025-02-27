WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CTE_CustDetails.c_name,
        CTE_CustDetails.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        (SELECT 
            c.c_custkey,
            c.c_name,
            c.c_acctbal
         FROM 
            customer c
         WHERE 
            c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
         ) AS CTE_CustDetails ON o.o_custkey = CTE_CustDetails.c_custkey
),
TopPartSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) >= 100
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice BETWEEN 10.00 AND 100.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    JSON_AGG(DISTINCT json_build_object('cust_name', coalesce(CTE_CustDetails.c_name, 'Unknown'), 'acct_bal', CTE_CustDetails.c_acctbal)) AS customer_info
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    (SELECT 
        lineitem.l_orderkey,
        lineitem.l_partkey,
        lineitem.l_extendedprice,
        lineitem.l_discount
     FROM 
        lineitem 
     WHERE 
        l_returnflag = 'N' 
     AND 
        EXISTS (SELECT 1 FROM orders o2 WHERE o2.o_orderkey = lineitem.l_orderkey AND o2.o_orderstatus <> 'F') 
    ) AS lo ON lo.l_orderkey = o.o_orderkey
JOIN 
    orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN 
    FilteredParts p ON p.p_partkey = lo.l_partkey
LEFT JOIN 
    RankedOrders CTE_CustDetails ON CTE_CustDetails.o_orderkey = o.o_orderkey
WHERE 
    r.r_comment IS NOT NULL OR (r.r_comment IS NULL AND o.o_orderstatus <> 'O')
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 100 OFFSET 10;
