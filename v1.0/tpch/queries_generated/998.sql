WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        sp.supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplierPartCounts sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(SUM(hp.p_retailprice), 0) AS total_high_value_parts,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    AVG(co.total_spent) AS avg_customer_spent
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueParts hp ON hp.p_comment LIKE '%' || n.n_name || '%'
LEFT JOIN 
    customer co ON n.n_nationkey = co.c_nationkey
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(co.c_custkey) > 0
ORDER BY 
    total_high_value_parts DESC, unique_customers DESC
LIMIT 10;
