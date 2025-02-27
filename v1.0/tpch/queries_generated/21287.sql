WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '2023-01-01' AND o.o_orderstatus IN ('O', 'F')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
),

HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        COALESCE(l.l_quantity, 0) AS total_qty,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_ext_price,
        CASE 
            WHEN COUNT(l.l_orderkey) > 0 THEN 'Has Line Items'
            ELSE 'No Line Items'
        END AS line_item_status
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
    HAVING 
        sum(l.l_quantity) > 100 OR line_item_status = 'No Line Items'
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT coalesce(c.c_custkey, -1)) AS customer_count,
    SUM(CASE WHEN hvo.total_qty IS NOT NULL THEN hvo.total_ext_price ELSE 0 END) AS total_order_value,
    SUM(CASE WHEN s.total_supply_value IS NOT NULL THEN s.total_supply_value ELSE 0 END) AS supplier_value,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    HighValueOrders hvo ON c.c_custkey = hvo.o_orderkey
LEFT JOIN 
    SupplierStats s ON s.s_suppkey = (SELECT MIN(ps_suppkey) FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = hvo.o_orderkey))
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN hvo.total_qty IS NULL THEN 1 ELSE 0 END) > 0 OR
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    n.n_name ASC
WITHIN GROUP (ORDER BY supplier_value DESC);
