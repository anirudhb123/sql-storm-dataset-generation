WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(cod.total_orders, 0) AS total_orders,
    COALESCE(cod.total_spent, 0) AS total_spent
FROM 
    part p
LEFT JOIN 
    supplier s ON p.p_partkey = s.s_suppkey; -- assuming partkey maps to supplier for demonstration
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN 
    CustomerOrderDetails cod ON s.s_suppkey = cod.c_custkey
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
WHERE 
    (p.p_retailprice > 100 OR r.r_name IS NULL)
    AND (1 = (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey) OR sp.total_avail_qty IS NULL)
ORDER BY 
    total_supply_cost DESC,
    total_orders DESC
FETCH FIRST 10 ROWS ONLY;
