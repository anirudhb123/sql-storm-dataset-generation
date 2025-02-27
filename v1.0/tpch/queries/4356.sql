WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name AS nation,
    p.p_name AS part_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_revenue,
    AVG(ss.avg_supply_cost) AS average_supply_cost,
    AVG(cp.total_spent) AS average_customer_spending
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerPurchases cp ON cp.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    n.n_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 0
ORDER BY 
    total_revenue DESC, average_customer_spending DESC
LIMIT 10;