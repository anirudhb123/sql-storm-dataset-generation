
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), SupplierDetails AS (
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
), CustomerOrders AS (
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
)
SELECT 
    COALESCE(cd.c_name, 'Unknown Customer') AS customer_name,
    o.o_orderkey,
    o.o_totalprice AS order_total,
    s.s_name AS supplier_name,
    sd.total_avail_qty,
    sd.total_supply_cost,
    EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_desc
FROM 
    RankedOrders o
LEFT JOIN 
    CustomerOrders cd ON cd.c_custkey IN (SELECT DISTINCT o2.o_custkey FROM orders o2 WHERE o2.o_orderkey = o.o_orderkey)
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    supplier s ON sd.s_suppkey = s.s_suppkey
WHERE 
    o.rn <= 5 
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
ORDER BY 
    order_total DESC, customer_name;
