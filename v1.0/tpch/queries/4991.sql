
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    sep.nation_name,
    COUNT(DISTINCT cust.c_custkey) AS total_customers,
    SUM(cust.total_spending) AS total_revenue,
    COUNT(DISTINCT ps.p_partkey) AS total_parts,
    COALESCE(MAX(ps.total_supply_cost), 0) AS max_supply_cost,
    AVG(CASE WHEN sep.rank_within_nation <= 3 THEN sep.s_acctbal ELSE NULL END) AS avg_top_supplier_acctbal
FROM 
    SupplierDetails sep
LEFT JOIN 
    CustomerOrders cust ON sep.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = (
            SELECT customers.c_nationkey 
            FROM customer customers 
            WHERE customers.c_custkey = cust.c_custkey
        )
    )
LEFT JOIN 
    PartSupplierInfo ps ON ps.total_supply_cost > 0
WHERE 
    sep.rank_within_nation <= 5
GROUP BY 
    sep.nation_name
HAVING 
    SUM(cust.total_spending) > 50000
ORDER BY 
    total_revenue DESC;
