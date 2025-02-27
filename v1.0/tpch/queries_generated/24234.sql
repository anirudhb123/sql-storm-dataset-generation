WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Unknown' 
        END AS order_status_desc
    FROM 
        orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Size Not Available'
            WHEN p.p_size = 0 THEN 'Invalid Size'
            ELSE CAST(p.p_size AS VARCHAR)
        END AS size_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
OrderLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(*) AS item_count,
        SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.order_status_desc,
    ps.avg_supply_cost,
    fp.p_name,
    fp.size_description,
    oli.total_revenue,
    oli.item_count,
    oli.return_count
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierStats ps ON ps.avg_supply_cost > (SELECT AVG(s_avg.avg_supply_cost) FROM SupplierStats s_avg)
LEFT JOIN 
    FilteredParts fp ON EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey AND ps.ps_availqty > 100)
LEFT JOIN 
    OrderLineItems oli ON oli.l_orderkey = o.o_orderkey
WHERE 
    (o.o_totalprice IS NOT NULL OR ps.total_available_qty IS NULL)
    AND o.rn < 5
ORDER BY 
    o.o_orderdate DESC, 
    fp.p_name;
