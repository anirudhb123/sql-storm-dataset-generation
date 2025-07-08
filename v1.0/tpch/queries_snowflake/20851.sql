
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        COALESCE(c.c_mktsegment, 'Unknown') AS mkt_segment
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5 OR SUM(ps.ps_availqty) IS NULL
),
JoinResult AS (
    SELECT 
        r.r_name,
        ns.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(COALESCE(ts.supplier_value, 0)) AS total_supplier_value
    FROM 
        region r
    LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN customer c ON c.c_nationkey = ns.n_nationkey
    LEFT JOIN CustomerStats cs ON c.c_custkey = cs.c_custkey
    LEFT JOIN TopSuppliers ts ON cs.mkt_segment = COALESCE(c.c_mktsegment, 'Unknown')
    GROUP BY 
        r.r_name, ns.n_name
)
SELECT 
    jr.r_name,
    jr.n_name,
    jr.customer_count,
    jr.total_supplier_value,
    ROW_NUMBER() OVER (ORDER BY jr.total_supplier_value DESC) AS region_rank
FROM 
    JoinResult jr
WHERE 
    jr.customer_count > 0
    AND (jr.total_supplier_value IS NULL OR jr.total_supplier_value > (SELECT AVG(total_spent) FROM CustomerStats))
ORDER BY 
    region_rank;
