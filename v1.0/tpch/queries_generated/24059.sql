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
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        LEAD(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS next_supplycost
    FROM 
        partsupp ps 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(CAST(SUM(o.o_totalprice) AS decimal(12, 2)), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
MaxSupplyCost AS (
    SELECT 
        ps.ps_partkey,
        MAX(ps.ps_supplycost) AS max_cost
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(cp.total_spent) AS avg_customer_spending,
    AVG(sp.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS finalized_orders,
    (SELECT COUNT(*) FROM RankedOrders WHERE rn = 1) AS highest_value_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_suppkey AND sp.next_supplycost IS NULL
LEFT JOIN 
    CustomerOrders cp ON s.s_suppkey = cp.c_custkey
LEFT JOIN 
    MaxSupplyCost msc ON sp.ps_partkey = msc.ps_partkey AND sp.ps_supplycost = msc.max_cost
WHERE 
    (sp.ps_availqty > 0 OR sp.ps_supplycost < 10.00)
    AND (n.n_name NOT LIKE '%land' OR n.n_name IS NULL)
    AND r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    supplier_count DESC, avg_customer_spending ASC;
