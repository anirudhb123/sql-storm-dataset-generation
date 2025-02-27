WITH CustomerOrders AS (
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
HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        CustomerOrders co
    INNER JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 1000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OverstockedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        sp.total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        (sp.total_supply_cost IS NULL OR sp.total_supply_cost > 50000) 
        AND p.p_size > 10
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    hs.c_name,
    hs.total_spent,
    op.p_name,
    ns.n_name,
    ns.supplier_count,
    ns.total_balance,
    RANK() OVER (PARTITION BY ns.n_nationkey ORDER BY hs.total_spent DESC) AS rank_within_nation
FROM 
    HighSpenders hs
JOIN 
    OverstockedParts op ON hs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = hs.c_custkey))
JOIN 
    NationSummary ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM customer c INNER JOIN nation n ON c.c_nationkey = n.n_nationkey WHERE c.c_custkey = hs.c_custkey)
WHERE 
    hs.total_spent BETWEEN 1000 AND 5000
ORDER BY 
    ns.n_nationkey, hs.total_spent DESC;
