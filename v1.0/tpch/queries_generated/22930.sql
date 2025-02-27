WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
      AND o.o_orderstatus IN ('O', 'P')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
      AND s.s_name LIKE 'S%'
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        SUM(CASE WHEN l.l_discount >= 0.10 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS high_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_discount
)
SELECT 
    r.r_name,
    COUNT(DISTINCT coalesce(o.o_orderkey, 0)) AS order_count,
    COUNT(DISTINCT sd.s_suppkey) AS supplier_count,
    SUM(hv.high_value) AS potential_revenue
FROM 
    RankedOrders o
FULL OUTER JOIN 
    SupplierDetails sd ON sd.total_supplycost > 10000
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey))
LEFT JOIN 
    HighValueLineItems hv ON hv.l_orderkey = o.o_orderkey
WHERE 
    r.r_name IS NOT NULL
  AND (o.o_orderstatus = 'P' OR o.o_orderstatus IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(hv.high_value) IS NOT NULL 
    AND COUNT(DISTINCT sd.s_suppkey) > 2
ORDER BY 
    potential_revenue DESC, r.r_name;
