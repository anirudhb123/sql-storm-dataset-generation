WITH RECURSIVE CustomerSales (c_custkey, c_name, total_spent, order_count) AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (
            SELECT AVG(total_spent) 
            FROM CustomerSales
        )
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.total_available,
        ps.total_supply_cost
    FROM 
        part p
    JOIN 
        PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.total_available > 100
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        HighValueCustomers cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.spending_rank,
    tp.p_partkey,
    tp.p_name,
    tp.total_available,
    tp.total_supply_cost,
    COALESCE(avg(l.l_discount), 0) AS avg_discount
FROM 
    CustomerRanked cr
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = cr.c_custkey
    )
JOIN 
    TopParts tp ON tp.p_partkey = l.l_partkey
GROUP BY 
    cr.c_custkey, cr.c_name, cr.spending_rank, tp.p_partkey, tp.p_name, tp.total_available, tp.total_supply_cost
ORDER BY 
    cr.spending_rank ASC, tp.total_supply_cost DESC;
