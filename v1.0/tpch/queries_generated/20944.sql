WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(s.s_acctbal) AS max_supplier_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerNationalDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL 
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS net_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    coalesce(c.c_name, 'Unknown Customer') AS customer_name,
    rd.order_rank,
    rd.o_totalprice,
    sp.total_available,
    sp.avg_supply_cost,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    COALESCE(SUM(li.net_revenue), 0) AS total_net_revenue,
    CASE 
        WHEN SUM(li.net_revenue) > 10000 THEN 'High Revenue'
        WHEN SUM(li.net_revenue) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    RANK() OVER (PARTITION BY n.n_name ORDER BY COUNT(DISTINCT c.c_custkey) DESC) AS customer_ranking
FROM 
    CustomerNationalDetails c
LEFT JOIN 
    RankedOrders rd ON c.c_custkey = rd.o_custkey
LEFT JOIN 
    SupplierPartInfo sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rd.o_orderkey)
LEFT JOIN 
    FilteredLineItems li ON li.l_orderkey = rd.o_orderkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    c.c_name, rd.order_rank, rd.o_totalprice, sp.total_available, sp.avg_supply_cost, n.n_name
ORDER BY 
    revenue_category DESC, total_net_revenue DESC;
