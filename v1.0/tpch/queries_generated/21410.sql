WITH RankedOrders AS (
    SELECT 
        o_orderkey, 
        o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS order_rank
    FROM 
        orders
    WHERE 
        o_orderdate >= DATEADD(day, -30, GETDATE())
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice IS NOT NULL)
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)

SELECT 
    r.r_name,
    COALESCE(SUM(sp.ps_availqty), 0) AS total_available_quantity,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
    COUNT(DISTINCT hc.c_custkey) AS high_value_customers,
    ROW_NUMBER() OVER (ORDER BY SUM(sp.ps_availqty) DESC) AS availability_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_suppkey AND sp.rank_cost = 1
LEFT JOIN 
    lineitem l ON sp.ps_partkey = l.l_partkey
LEFT JOIN 
    HighValueCustomers hc ON hc.total_spent > (SELECT AVG(total_spent) FROM HighValueCustomers)
WHERE 
    s.s_acctbal IS NOT NULL AND 
    r.r_comment NOT LIKE '%test%'
GROUP BY 
    r.r_name
HAVING 
    SUM(sp.ps_availqty) > 100
ORDER BY 
    availability_rank
UNION ALL
SELECT 
    'Other' AS r_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_available_quantity,
    COUNT(DISTINCT l.l_returnflag) AS total_returns,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_acctbal < 500) AS high_value_customers, 
    999 AS availability_rank
FROM 
    partsupp ps
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    ps.ps_availqty < 10
