WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    COALESCE(cd.c_name, 'Unknown Customer') AS customer_name,
    cd.total_spent,
    COALESCE(ro.o_orderstatus, 'No Status') AS order_status,
    ro.order_rank,
    sd.total_parts,
    sd.total_supply_cost,
    CASE 
        WHEN cd.total_spent IS NULL THEN 'Inactive'
        WHEN cd.total_spent >= 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_segment,
    CONCAT('Total Spent: $', FORMAT(cd.total_spent, 2)) AS formatted_spent,
    (SELECT AVG(o_totalprice) FROM RankedOrders WHERE o_orderstatus = 'F' AND o_totalprice > 0) AS avg_fulfilled_price
FROM 
    CustomerOrders cd
LEFT JOIN 
    RankedOrders ro ON cd.order_count > 0 AND ro.o_orderkey = (SELECT TOP 1 o_orderkey FROM orders WHERE o_custkey = cd.c_custkey ORDER BY o_orderdate DESC)
LEFT JOIN 
    SupplierDetails sd ON sd.total_parts > 0
WHERE 
    cd.total_spent IS NOT NULL OR sd.total_parts IS NOT NULL
ORDER BY 
    cd.total_spent DESC, 
    sd.total_supply_cost ASC;
