WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerBalance AS (
    SELECT 
        c.c_nationkey,
        SUM(c.c_acctbal) AS total_balance
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
    HAVING 
        SUM(c.c_acctbal) > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber ASC) AS lineitem_order
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.total_parts_supplied, 0) AS parts_supplied,
    s.total_supply_cost,
    c.total_balance,
    li.net_revenue,
    li.total_returns,
    CASE 
        WHEN li.total_returns > 0 THEN 'Returned'
        ELSE 'Delivered'
    END AS delivery_status,
    RANK() OVER (ORDER BY COALESCE(li.net_revenue, 0) DESC) AS revenue_rank,
    CASE 
        WHEN li.net_revenue IS NULL THEN NULL 
        WHEN li.total_returns > 0 THEN 'Returns Included'
        ELSE 'No Returns'
    END AS return_status
FROM 
    part p
LEFT JOIN 
    SupplierSummary s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = p.p_mfgr LIMIT 1)
LEFT JOIN 
    CustomerBalance c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany') -- assuming Germany for example
LEFT JOIN 
    LineItemSummary li ON li.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders ro WHERE ro.order_rank = 1)
WHERE 
    p.p_retailprice >= (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
    AND p.p_comment NOT LIKE '%fragile%'
ORDER BY 
    revenue_rank, 
    p.p_partkey;
