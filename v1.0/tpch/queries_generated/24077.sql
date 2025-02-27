WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND
        o.o_totalprice IS NOT NULL
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_discount,
        l.l_tax,
        l.l_quantity,
        l.l_extendedprice,
        l.l_returnflag,
        CASE 
            WHEN l.l_discount != 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND (l.l_shipdate < CURRENT_DATE - INTERVAL '30 days' OR l.l_shipdate IS NULL)
)
SELECT 
    n.n_name AS nation_name,
    p.p_name AS part_name,
    CONCAT('Supplier ', s.s_name, ': ', COALESCE(s.s_comment, 'No comment')) AS supplier_info,
    SUM(l.net_price) AS total_net_price,
    AVG(sp.avg_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MIN(fo.l_quantity) AS min_line_quantity,
    MAX(CASE WHEN fo.l_tax > 0.2 THEN 'High Tax' ELSE 'Normal Tax' END) AS tax_category
FROM 
    RankedOrders ro
JOIN 
    FilteredLineItems fo ON ro.o_orderkey = fo.l_orderkey
JOIN 
    partsupp sp ON fo.l_partkey = sp.ps_partkey
JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
JOIN 
    part p ON sp.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    ro.rn = 1 
    AND (ro.o_orderstatus = 'O' OR ro.o_totalprice BETWEEN 100.00 AND 500.00)
GROUP BY 
    n.n_name, p.p_name, s.s_name, s.s_comment
HAVING 
    SUM(l.net_price) > 1000
ORDER BY 
    total_net_price DESC, nation_name ASC, part_name ASC;
