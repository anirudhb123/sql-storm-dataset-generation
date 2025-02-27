WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
FinalReport AS (
    SELECT 
        h.c_custkey,
        h.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_order_value,
        COALESCE(MAX(r.order_rank), 0) AS max_order_rank,
        COALESCE(SUM(s.total_supply_cost), 0) AS supplier_cost
    FROM 
        HighValueCustomers h
    LEFT JOIN lineitem l ON h.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
    LEFT JOIN RankedOrders r ON h.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
    LEFT JOIN SupplierSummary s ON l.l_suppkey = s.s_suppkey
    GROUP BY 
        h.c_custkey, h.c_name
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.total_order_value,
    f.max_order_rank,
    f.supplier_cost
FROM 
    FinalReport f
WHERE 
    f.total_order_value > 5000
ORDER BY 
    f.total_order_value DESC, f.c_name ASC;
