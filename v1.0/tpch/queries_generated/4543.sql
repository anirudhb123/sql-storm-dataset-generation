WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_partkey) AS item_count,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), NationOverview AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_balance,
        RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS balance_rank
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_balance,
    ss.total_cost,
    od.total_revenue,
    CASE 
        WHEN ns.total_balance IS NULL THEN 'No balance info'
        ELSE 'Balance info available'
    END AS balance_info,
    COALESCE(ss.part_count, 0) AS supplier_part_count,
    od.avg_quantity,
    od.o_orderstatus
FROM 
    NationOverview ns
LEFT JOIN 
    SupplierStats ss ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = ss.s_suppkey)
LEFT JOIN 
    OrderDetails od ON od.total_revenue > 10000 -- only considering high revenue orders
WHERE 
    ns.supplier_count > 5
ORDER BY 
    ns.total_balance DESC, od.total_revenue DESC;
