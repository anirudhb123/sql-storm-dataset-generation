WITH CustomerOrderSummary AS (
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
        c.c_custkey, c.c_name
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        MAX(p.p_retailprice) AS highest_price
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        cus.c_custkey, 
        cus.c_name,
        cus.total_spent,
        RANK() OVER (ORDER BY cus.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrderSummary cus
    WHERE 
        cus.total_spent IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        sup.s_suppkey, 
        sup.s_name,
        sup.total_supply_value,
        RANK() OVER (ORDER BY sup.total_supply_value DESC) AS supply_rank
    FROM 
        SupplierPartSummary sup
    WHERE 
        sup.total_supply_value IS NOT NULL
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    coalesce(c.total_spent, 0) AS total_spent,
    coalesce(s.total_supply_value, 0) AS total_supply_value,
    (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = c.c_custkey) AS order_count,
    (SELECT COUNT(*) FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)) AS lineitem_count
FROM 
    TopCustomers c
FULL OUTER JOIN 
    TopSuppliers s ON c.spending_rank = s.supply_rank
WHERE 
    (c.total_spent > 1000 OR s.total_supply_value > 10000)
ORDER BY 
    total_spent DESC NULLS LAST, total_supply_value DESC NULLS LAST;
