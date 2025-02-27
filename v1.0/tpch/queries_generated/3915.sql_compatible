
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS PriceRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
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
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    CASE 
        WHEN r.PriceRank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS OrderType,
    c.c_name,
    sp.total_available,
    sp.total_cost,
    COALESCE(co.total_orders, 0) AS total_orders_by_customer,
    COALESCE(co.total_spent, 0) AS total_spent_by_customer,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    (SELECT MAX(l_quantity) FROM lineitem WHERE l_orderkey = r.o_orderkey) AS max_line_quantity
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem li ON r.o_orderkey = li.l_orderkey
LEFT JOIN 
    customer c ON c.c_custkey = r.o_orderkey
LEFT JOIN 
    SupplierPart sp ON sp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = c.c_custkey)
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = c.c_custkey
WHERE 
    r.PriceRank <= 10
GROUP BY 
    r.o_orderkey, r.o_totalprice, r.o_orderdate, r.PriceRank, c.c_name, sp.total_available, sp.total_cost, co.total_orders, co.total_spent
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
