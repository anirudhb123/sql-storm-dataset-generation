
WITH RankedCustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey, c.c_name
), 
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), 
OrderLineData AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND l.l_shipdate <= CAST('1998-10-01' AS DATE)
)
SELECT 
    rcs.c_name,
    COALESCE(spi.p_name, 'Unknown Part') AS part_name,
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue,
    COUNT(DISTINCT ol.o_orderkey) AS order_count
FROM 
    RankedCustomerSpend rcs
LEFT JOIN 
    OrderLineData ol ON rcs.c_custkey = ol.o_orderkey
LEFT JOIN 
    SupplierPartInfo spi ON ol.l_partkey = spi.ps_partkey
WHERE 
    rcs.spend_rank <= 10
GROUP BY 
    rcs.c_name, spi.p_name
HAVING 
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) > 1000
ORDER BY 
    revenue DESC
LIMIT 5;
