WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_totalprice IS NOT NULL 
        AND o.o_orderdate >= '2023-01-01'
),
HighValueOrders AS (
    SELECT 
        co.c_custkey, 
        co.o_orderkey, 
        co.o_orderstatus, 
        co.o_totalprice
    FROM 
        CustomerOrders co
    WHERE 
        co.order_rank <= 5
)
SELECT 
    cs.c_custkey, 
    cs.o_orderkey, 
    rs.s_suppkey, 
    rs.s_name, 
    COALESCE(strcmp(rs.s_name, 'SupplierX'), 0) AS is_supplier_x, 
    (CASE 
        WHEN cs.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END) AS order_status,
    MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_final_price
FROM 
    HighValueOrders cs
LEFT JOIN 
    lineitem l ON cs.o_orderkey = l.l_orderkey
LEFT OUTER JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
WHERE 
    rs.rank = 1 
    AND l.l_returnflag IS NULL 
GROUP BY 
    cs.c_custkey, 
    cs.o_orderkey, 
    rs.s_suppkey, 
    rs.s_name, 
    cs.o_orderstatus
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_orderkey = cs.o_orderkey)
ORDER BY 
    cs.c_custkey, 
    cs.o_orderkey DESC; 
