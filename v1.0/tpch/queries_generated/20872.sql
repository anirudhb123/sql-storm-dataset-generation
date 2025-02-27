WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        cs.total_spent,
        cs.order_count,
        cs.last_order_date
    FROM 
        CustomerSummary cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    c.c_name,
    cs.total_spent,
    cs.order_count,
    ps.p_name,
    ps.total_available,
    s.s_name,
    s.part_count,
    CASE 
        WHEN cs.last_order_date IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    COUNT(DISTINCT l.l_orderkey) AS unique_line_items,
    string_agg(DISTINCT s.s_name, ', ') FILTER (WHERE s.part_count > 5) AS suppliers_with_many_parts,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity
FROM 
    HighValueCustomers cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    PartSupplier ps ON ps.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = l.l_suppkey
GROUP BY 
    c.c_name, cs.total_spent, cs.order_count, ps.p_name, ps.total_available, s.s_name, s.part_count, cs.last_order_date
HAVING 
    SUM(l.l_discount) < (SELECT AVG(l2.l_discount) FROM lineitem l2 WHERE l2.l_discount IS NOT NULL)
ORDER BY 
    cs.total_spent DESC; 
