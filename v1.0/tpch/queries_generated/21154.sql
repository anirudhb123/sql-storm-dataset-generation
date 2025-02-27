WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
CustomerNation AS (
    SELECT 
        c.c_custkey, 
        n.n_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS nation_cust_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL 
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost) > 100.00
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(NULLIF(p.p_mfgr, ''), 'Unknown') AS manufacturer,
        p.p_retailprice * 1.1 AS adjusted_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
)
SELECT 
    cn.n_name AS nation_name,
    pi.manufacturer,
    pi.p_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(pi.adjusted_price) AS total_value,
    AVG(l.l_discount) AS avg_discount
FROM 
    RankedOrders ro
JOIN 
    CustomerNation cn ON ro.o_orderkey IN (
        SELECT 
            o.o_orderkey
        FROM 
            orders o 
        WHERE 
            o.o_custkey = cn.c_custkey AND cn.nation_cust_rank <= 5
    )
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    PartInfo pi ON l.l_partkey = pi.p_partkey
LEFT JOIN 
    SupplierCost sc ON pi.p_partkey = sc.ps_partkey
WHERE 
    pi.adjusted_price > (SELECT AVG(adjusted_price) FROM PartInfo WHERE p_size IS NOT NULL)
    AND sc.total_supply_cost IS NULL 
GROUP BY 
    cn.n_name, pi.manufacturer, pi.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_value DESC, nation_name;
