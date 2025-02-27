
WITH RankedSupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate = o.o_orderdate)
)
SELECT 
    rsc.ps_partkey,
    rsc.s_name,
    rsc.ps_supplycost,
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.o_orderdate,
    COALESCE(NULLIF(hvo.c_name, ''), 'Unknown Customer') AS customer_name,
    (rsc.ps_supplycost * hvo.o_totalprice) AS total_value
FROM 
    RankedSupplierCosts rsc
FULL OUTER JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderdate = hvo.o_orderdate)
WHERE 
    rsc.rnk = 1
    AND hvo.rn <= 5
ORDER BY 
    rsc.ps_partkey, hvo.o_orderdate DESC;
