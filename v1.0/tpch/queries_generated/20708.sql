WITH CTE_Supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CTE_Order_Summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CTE_Customer_Segment AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
CTE_Nation_Stats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    COALESCE(ns.avg_account_balance, 0) AS average_account_balance,
    cs.mkt_segment,
    cs.order_count,
    SUM(coalesce(os.total_price, 0)) AS total_order_value,
    SUM(coalesce(ss.total_supply_cost, 0)) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CTE_Nation_Stats ns ON n.n_name = ns.n_name
LEFT JOIN 
    CTE_Customer_Segment cs ON cs.c_mktsegment = 'AUTOMOBILE'
LEFT JOIN 
    CTE_Order_Summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_mktsegment = cs.mkt_segment))
LEFT JOIN 
    CTE_Supplier ss ON ss.total_parts > 10
WHERE 
    (ns.supplier_count IS NULL OR ns.supplier_count > 5) AND 
    (cs.order_count IS NULL OR cs.order_count < 100)
GROUP BY 
    r.r_name, ns.avg_account_balance, cs.mkt_segment, cs.order_count
ORDER BY 
    average_account_balance DESC,
    total_order_value DESC
LIMIT 50;
