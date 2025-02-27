WITH CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        c.c_acctbal AS account_balance,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, c.c_acctbal
),
PartSupplierInfo AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ps.ps_comment AS supply_comment
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedData AS (
    SELECT 
        co.customer_name,
        co.account_balance,
        co.total_spent,
        co.total_orders,
        psi.part_name,
        SUM(psi.available_quantity) AS total_available_quantity,
        AVG(psi.supply_cost) AS average_supply_cost,
        STRING_AGG(psi.supplier_name, ', ') AS suppliers_list
    FROM 
        CustomerOrders co
    JOIN 
        lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.customer_name)
    JOIN 
        PartSupplierInfo psi ON psi.part_name = (SELECT p.p_name FROM part p WHERE p.p_partkey = l.l_partkey)
    GROUP BY 
        co.customer_name, co.account_balance, co.total_spent, co.total_orders, psi.part_name
)
SELECT 
    ad.customer_name,
    ad.account_balance,
    ad.total_spent,
    ad.total_orders,
    ad.part_name,
    ad.total_available_quantity,
    ad.average_supply_cost,
    ad.suppliers_list
FROM 
    AggregatedData ad
WHERE 
    ad.account_balance > 1000
ORDER BY 
    ad.total_spent DESC, ad.total_orders DESC;
