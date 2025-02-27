
WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
        p.p_brand
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_brand
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY AVG(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_brand
)
SELECT 
    r.r_name,
    COUNT(DISTINCT so.s_suppkey) AS supplier_count,
    SUM(co.total_spent) AS total_customer_spend,
    MAX(pd.avg_price) AS highest_avg_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier so ON n.n_nationkey = so.s_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = so.s_suppkey AND ps.ps_availqty > 0)
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT so.s_suppkey) > 0 AND SUM(co.total_spent) IS NOT NULL
ORDER BY 
    total_customer_spend DESC;
