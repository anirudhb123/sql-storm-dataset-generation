
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty,
        MAX(s.s_acctbal) AS max_acct_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
ComplexJoin AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
        CASE 
            WHEN sp.avg_avail_qty IS NULL THEN 'No Availability'
            ELSE CAST(sp.avg_avail_qty AS VARCHAR(255))
        END AS availability_status
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE 
            WHEN o.o_orderstatus = 'O' THEN o.o_totalprice 
            ELSE 0 
        END) AS total_open_order_amount,
    AVG(CASE 
            WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) 
            ELSE NULL 
        END) AS average_returned_price,
    STRING_AGG(COALESCE(CONCAT(cp.p_name, ': ', cp.availability_status), 'Unknown Part: No Availability'), '; ') AS part_availability
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    ComplexJoin cp ON cp.p_partkey = li.l_partkey
WHERE 
    r.r_name LIKE 'A%' 
    AND (o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' OR o.o_orderdate IS NULL)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 
    AND SUM(o.o_totalprice) IS NOT NULL
ORDER BY 
    r.r_name;
