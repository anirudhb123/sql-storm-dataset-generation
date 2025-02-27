WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
)
SELECT 
    cus.c_name AS customer_name,
    cus.total_orders,
    cus.total_spent,
    supp.s_name AS supplier_name,
    supp.total_parts_supplied,
    supp.total_supply_value,
    ord.o_orderkey,
    ord.o_orderdate,
    ord.o_totalprice,
    ord.rank_order
FROM 
    CustomerOrderSummary cus
FULL OUTER JOIN 
    SupplierPartSummary supp ON cus.total_orders > 0 OR supp.total_parts_supplied > 0
LEFT JOIN 
    RankedOrders ord ON cus.total_orders > 10 AND ord.rank_order <= 5
WHERE 
    (cus.total_spent IS NULL AND supp.total_supply_value IS NOT NULL) OR 
    (cus.total_spent IS NOT NULL AND supp.total_supply_value IS NULL) OR 
    (cus.total_spent > 1000 AND supp.total_supply_value < 5000)
ORDER BY 
    cus.total_spent DESC NULLS LAST, 
    supp.total_supply_value ASC;
