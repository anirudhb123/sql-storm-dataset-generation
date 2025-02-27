WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_address, ''), 'Unknown Address') AS address,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), 
OrderLineInfo AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_line_value,
        COUNT(DISTINCT li.l_partkey) AS unique_parts
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    sd.s_name AS supplier_name,
    oli.total_line_value,
    o.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY oli.total_line_value DESC) AS row_num,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown Status' 
    END AS order_status_desc,
    (SELECT COUNT(*) FROM RankedOrders r WHERE r.order_rank = 1) as top_order_count
FROM 
    RankedOrders o
LEFT JOIN 
    HighValueCustomers c ON o.o_orderkey = (SELECT ol.l_orderkey 
                                              FROM lineitem ol 
                                              WHERE ol.l_orderkey = o.o_orderkey 
                                              LIMIT 1)
LEFT JOIN 
    OrderLineInfo oli ON o.o_orderkey = oli.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT li.l_partkey 
            FROM lineitem li 
            WHERE li.l_orderkey = o.o_orderkey
        ) AND ps.ps_suppkey = sd.s_suppkey
    )
WHERE 
    o.o_totalprice > (SELECT AVG(o2.o_totalprice) 
                      FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
ORDER BY o.o_orderdate DESC, o.o_orderkey;
