WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.order_count,
        cust.total_spent
    FROM 
        CustomerOrderStats cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count,
    AVG(s.total_supply_cost) AS average_supply_cost,
    SUM(CASE WHEN lo.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cust ON n.n_nationkey = cust.c_nationkey
LEFT JOIN 
    HighValueCustomers hvc ON cust.c_custkey = hvc.c_custkey
LEFT JOIN 
    lineitem lo ON lo.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cust.c_custkey)
LEFT JOIN 
    SupplierStats s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
GROUP BY 
    r.r_name
ORDER BY 
    high_value_customer_count DESC;
