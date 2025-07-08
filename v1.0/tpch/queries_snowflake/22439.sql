
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        RANK() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O') AND 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal < 100.00 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS balance_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < DATEADD(DAY, -30, '1998-10-01')
)
SELECT 
    p.p_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(oli.net_revenue), 0) AS total_revenue,
    LISTAGG(DISTINCT sd.balance_status) AS supplier_balance_statuses
FROM 
    part p
LEFT JOIN 
    PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    RankedOrders o ON ps.ps_partkey = o.o_orderkey
LEFT JOIN 
    OrderLineItems oli ON o.o_orderkey = oli.l_orderkey
JOIN 
    nation n ON sd.s_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_size > 20)
    AND (r.r_name IS NOT NULL OR sd.s_name IS NULL)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, r.r_name ASC;
