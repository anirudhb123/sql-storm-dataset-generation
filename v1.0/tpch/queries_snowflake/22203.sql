
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrdersWithLineItems AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_name AS supplier_name,
    r.total_supply_cost,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.order_total,
    CASE 
        WHEN r.rank_within_nation = 1 THEN 'Top Supplier'
        WHEN r.total_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE 'Regular Supplier'
    END AS supplier_status,
    CASE 
        WHEN c.customer_rank <= 10 THEN 'High Value'
        ELSE 'Standard'
    END AS customer_status
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    HighValueCustomers c ON r.s_suppkey = c.c_custkey
JOIN 
    OrdersWithLineItems o ON o.o_orderkey = c.c_custkey
WHERE 
    r.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
    OR r.total_supply_cost IS NULL
ORDER BY 
    r.total_supply_cost DESC, 
    o.order_total DESC;
