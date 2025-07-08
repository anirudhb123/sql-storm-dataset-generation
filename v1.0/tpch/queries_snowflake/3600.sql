WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
CustomerTotalSpend AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(ss.total_available, 0) AS total_available,
        COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE
        COALESCE(ss.total_available, 0) > 100
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_value,
    cs.total_spent,
    ts.s_name,
    ts.total_available,
    ts.avg_supply_cost
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    CustomerTotalSpend cs ON o.o_orderkey IN (
        SELECT o2.o_orderkey 
        FROM orders o2 
        WHERE o2.o_custkey = cs.c_custkey
    )
LEFT JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    o.order_rank <= 10
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.o_totalprice, cs.total_spent, ts.s_name, ts.total_available, ts.avg_supply_cost
ORDER BY 
    o.o_orderdate DESC, net_value DESC;