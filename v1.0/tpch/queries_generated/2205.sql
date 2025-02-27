WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 1000
),
NationSummary AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS num_customers,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    ns.n_name,
    COALESCE(ns.num_customers, 0) AS total_customers,
    COALESCE(ns.avg_account_balance, 0) AS average_balance,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ps.total_cost) AS total_part_cost,
    AVG(ro.o_totalprice) AS avg_order_value
FROM 
    NationSummary ns
LEFT JOIN 
    RankedOrders ro ON ns.num_customers > 0
LEFT JOIN 
    PartSupplier ps ON ps.p_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F'))
GROUP BY 
    ns.n_name
HAVING 
    AVG(ro.o_totalprice) IS NOT NULL 
    AND COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY 
    total_customers DESC, avg_order_value DESC;
