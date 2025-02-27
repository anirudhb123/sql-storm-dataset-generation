WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        SUM(ps.ps_supplycost) AS total_supply_cost
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
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        li.l_orderkey, 
        li.l_partkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        li.l_orderkey, li.l_partkey
),
RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        RANK() OVER (ORDER BY SUM(li.l_extendedprice) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        LineItemDetails li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name, 
    ns.n_nationkey, 
    ns.n_name, 
    ST.total_avail_qty, 
    ST.total_supply_cost, 
    CO.total_spent, 
    RP.p_name, 
    RP.part_rank
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    SupplierTotals ST ON ns.n_nationkey = ST.s_suppkey
FULL OUTER JOIN 
    CustomerOrders CO ON ns.n_nationkey = CO.c_custkey
INNER JOIN 
    RankedParts RP ON CO.order_count > 0 AND RP.part_rank <= 10
WHERE 
    (ST.total_supply_cost IS NOT NULL OR CO.total_spent IS NULL)
    AND RP.p_name LIKE '%Widget%'
ORDER BY 
    r.r_name, CO.total_spent DESC;
