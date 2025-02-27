
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_acct_balance,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
NationSupply AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(ss.total_supply_value), 0) AS total_supply_by_nation
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON ss.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
            WHERE s.s_nationkey = n.n_nationkey
        )
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.total_supply_by_nation,
    co.order_count,
    co.total_spent
FROM 
    NationSupply ns
FULL OUTER JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_custkey
WHERE 
    (ns.total_supply_by_nation > 500000 OR co.total_spent IS NULL)
    AND (co.spending_rank IS NULL OR co.spending_rank <= 5)
ORDER BY 
    ns.n_name, co.total_spent DESC NULLS LAST;
