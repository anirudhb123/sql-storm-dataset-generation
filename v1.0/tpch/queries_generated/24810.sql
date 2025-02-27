WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' AND 
        o.o_orderdate < '1996-01-01'
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost IS NOT NULL
    GROUP BY 
        ps.ps_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500.00
    GROUP BY 
        c.c_custkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_name,
        co.customer_total
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.customer_total > (SELECT AVG(customer_total) FROM CustomerOrders)
)
SELECT 
    p.p_name,
    r.r_name,
    sp.total_avail_qty,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    COUNT(DISTINCT co.c_custkey) AS num_high_value_customers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueCustomers co ON s.s_name = (SELECT s_name FROM supplier WHERE s_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderstatus = CASE WHEN p.p_size % 2 = 0 THEN 'O' ELSE 'F' END
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000.00)
GROUP BY 
    p.p_name, r.r_name, sp.total_avail_qty, sp.avg_supply_cost
HAVING 
    COUNT(DISTINCT co.c_custkey) > 0 
ORDER BY 
    p.p_name;
