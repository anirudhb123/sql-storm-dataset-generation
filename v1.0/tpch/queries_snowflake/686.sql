
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_mfgr
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
FinalReport AS (
    SELECT 
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        MAX(rs.total_cost) AS max_supplier_cost,
        tc.total_spent AS customer_total_spent
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON ns.n_nationkey = (SELECT s.s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
    LEFT JOIN 
        TopCustomers tc ON tc.c_custkey = (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey = rs.s_suppkey LIMIT 1)
    WHERE 
        rs.supplier_rank = 1
    GROUP BY 
        ns.n_name, rs.s_name, tc.total_spent
)

SELECT 
    fr.nation_name,
    fr.supplier_name,
    COALESCE(fr.max_supplier_cost, 0) AS max_supplier_cost,
    COALESCE(fr.customer_total_spent, 0) AS customer_total_spent
FROM 
    FinalReport fr
ORDER BY 
    fr.nation_name, fr.supplier_name;
