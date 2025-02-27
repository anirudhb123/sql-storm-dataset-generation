WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000 OR COUNT(o.o_orderkey) = 0
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
)

SELECT DISTINCT 
    hs.cust_name,
    ps.part_name,
    ps.total_available_qty,
    RANK() OVER (PARTITION BY hs.cust_name ORDER BY ps.avg_supply_cost DESC) AS rank_by_cost,
    CONCAT('Customer ', hs.cust_name, ' ordered part ', ps.part_name, ' with availability ', ps.total_available_qty) AS description
FROM 
    HighValueCustomers hs
JOIN 
    SupplierPartDetails ps ON hs.custkey = ps.s_suppkey 
LEFT JOIN 
    RankedOrders ro ON hs.custkey = ro.o_custkey AND ro.order_rank = 1
WHERE 
    ps.total_available_qty IS NOT NULL 
    AND (ro.o_totalprice IS NULL OR ro.o_totalprice < 5000)
ORDER BY 
    hs.c_name, ps.part_name
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
