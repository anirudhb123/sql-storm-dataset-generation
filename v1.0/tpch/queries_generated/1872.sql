WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    n.n_name,
    ns.supplier_count,
    ns.total_acctbal,
    hc.order_value,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY hc.order_value DESC) AS rank_by_order_value
FROM 
    part p
JOIN 
    SupplierCost sc ON p.p_partkey = sc.ps_partkey
JOIN 
    HighValueOrders hc ON sc.ps_suppkey = hc.o_orderkey
JOIN 
    nation n ON n.n_nationkey = (
        SELECT 
            s.s_nationkey 
        FROM 
            supplier s 
        WHERE 
            s.s_suppkey = sc.ps_suppkey
    )
JOIN 
    NationStats ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    p.p_retailprice > (
        SELECT 
            AVG(p2.p_retailprice) 
        FROM 
            part p2
    )
ORDER BY 
    n.n_name, rank_by_order_value;
