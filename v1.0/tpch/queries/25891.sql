WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), LineItemDetails AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_discount,
        li.l_extendedprice,
        li.l_shipdate,
        li.l_returnflag
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= '1997-01-01' AND li.l_shipdate <= '1997-12-31'
)
SELECT 
    sp.s_name,
    STRING_AGG(DISTINCT sp.p_name, ', ') AS part_names,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    AVG(li.l_quantity) AS avg_quantity_sold,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
FROM 
    SupplierParts sp
JOIN 
    LineItemDetails li ON sp.p_partkey = li.l_partkey
JOIN 
    CustomerOrders co ON li.l_orderkey = co.o_orderkey
GROUP BY 
    sp.s_suppkey, sp.s_name
HAVING 
    SUM(li.l_quantity) > 100
ORDER BY 
    net_revenue DESC;