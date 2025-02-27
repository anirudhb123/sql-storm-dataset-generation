WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(o.o_orderkey, 0) AS order_key,
    COALESCE(o.total_spent, 0) AS total_amount_spent,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(sp.ps_supplycost * (CASE WHEN sp.ps_supplycost IS NOT NULL THEN 1 ELSE 0 END)) AS total_supply_cost,
    r.r_name AS region_name
FROM 
    CustomerOrders o
FULL OUTER JOIN SupplierParts sp ON o.o_orderkey = sp.ps_partkey
LEFT JOIN nation n ON n.n_nationkey = (SELECT n_nationkey FROM customer WHERE c_custkey = o.c_custkey)
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.total_amount_spent > 1000
    OR sp.ps_supplycost < 500
GROUP BY 
    c.c_custkey, o.o_orderkey, s.s_suppkey, r.r_name
ORDER BY 
    customer_name, total_amount_spent DESC, total_supply_cost ASC;
