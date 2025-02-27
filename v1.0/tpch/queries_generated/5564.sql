WITH NationSupplier AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
), 
PartSupplier AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
CustomerOrder AS (
    SELECT 
        c.c_name AS customer_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    ns.nation_name,
    ns.supplier_count, 
    ns.total_acct_balance, 
    ps.total_available_qty,
    ps.average_supply_cost,
    co.customer_name,
    co.total_orders,
    co.total_spent
FROM 
    NationSupplier ns
JOIN 
    PartSupplier ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100.00)
JOIN 
    CustomerOrder co ON co.total_spent > 5000
WHERE 
    ns.supplier_count > 10
ORDER BY 
    ns.nation_name, 
    co.total_spent DESC
LIMIT 50;
