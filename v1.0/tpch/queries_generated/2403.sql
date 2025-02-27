WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
RichCustomers AS (
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
    r.r_name AS Region,
    n.n_name AS Nation,
    p.p_name AS Part_Name,
    IFNULL(rc.total_spent, 0) AS Customer_Spent,
    spd.total_available AS Total_Available,
    spd.avg_supply_cost AS Avg_Supply_Cost,
    o.rn AS Order_Rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierPartDetails spd ON spd.ps_partkey = p.p_partkey
LEFT JOIN 
    RichCustomers rc ON rc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (SELECT oo.o_orderkey FROM orders oo WHERE oo.o_custkey = rc.c_custkey ORDER BY oo.o_orderdate DESC LIMIT 1)
WHERE 
    p.p_retailprice > 100
ORDER BY 
    r.r_name, n.n_name, p.p_name;
