WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopCustomers AS (
    SELECT 
        r.r_name as region,
        o.o_orderkey,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY o.o_totalprice DESC) as customer_rank
    FROM 
        RankedOrders r 
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cust.c_name, 
    cust.o_orderkey, 
    cust.o_totalprice, 
    supp.part_count, 
    supp.total_supply_cost,
    COALESCE(cust.o_totalprice - supp.total_supply_cost, 0) AS net_profit
FROM 
    RankedOrders cust
LEFT JOIN 
    SupplierStats supp ON cust.o_orderkey = supp.s_suppkey
WHERE 
    cust.rn <= 5
ORDER BY 
    net_profit DESC
LIMIT 10;
