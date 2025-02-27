WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),

HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
    GROUP BY 
        ps.ps_partkey
),

SupplierNationCTE AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    rn.o_orderkey,
    rn.o_orderdate,
    pn.p_name,
    h.total_supply_value,
    sn.n_name AS supplier_nation,
    CASE 
        WHEN sn.supplier_count IS NULL THEN 'No Suppliers'
        ELSE sn.supplier_count::text
    END AS supplier_count
FROM 
    RankedOrders rn
LEFT JOIN 
    lineitem l ON rn.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueParts h ON l.l_partkey = h.ps_partkey
LEFT JOIN 
    SupplierNationCTE sn ON rn.c_nationkey = sn.n_nationkey
WHERE 
    rn.order_rank = 1
AND 
    h.total_supply_value IS NOT NULL
ORDER BY 
    rn.o_orderdate DESC, h.total_supply_value DESC;
