WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        COALESCE(MAX(o.o_totalprice), 0) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
MaxSupplyValue AS (
    SELECT 
        MAX(total_supply_value) AS max_supply_value
    FROM 
        SupplierPartStats
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    co.max_order_value,
    sp.total_supply_value,
    CASE 
        WHEN sp.total_supply_value = ms.max_supply_value THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status
FROM 
    CustomerOrderStats co
LEFT JOIN 
    SupplierPartStats sp ON sp.s_name = (SELECT s_name FROM supplier WHERE s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100)))
CROSS JOIN 
    MaxSupplyValue ms
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
    AND sp.total_supply_value IS NOT NULL
ORDER BY 
    co.total_spent DESC, co.order_count DESC;
