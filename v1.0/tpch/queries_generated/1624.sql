WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierProducts AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        p.p_mfgr,
        p.p_name,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_shipmode
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
)

SELECT 
    hvc.c_name AS customer_name,
    hvc.total_spent AS total_spent_by_customer,
    ss.s_name AS supplier_name,
    rsp.total_supply_cost AS supplier_total_supply_cost,
    sp.p_name AS product_name,
    SUM(sp.l_extendedprice * (1 - sp.l_discount)) AS revenue
FROM 
    HighValueCustomers hvc
LEFT OUTER JOIN 
    RankedSuppliers rsp ON rsp.supplier_rank = 1
JOIN 
    SupplierProducts sp ON sp.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hvc.c_custkey)
WHERE 
    rsp.total_supply_cost IS NOT NULL
GROUP BY 
    hvc.c_name, hvc.total_spent, rsp.s_name, rsp.total_supply_cost, sp.p_name
HAVING 
    SUM(sp.l_extendedprice * (1 - sp.l_discount)) > 1000
ORDER BY 
    hvc.total_spent DESC, rsp.total_supply_cost DESC;
