
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate <= DATE '1997-12-31'
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        d.total_orders, 
        d.total_spent,
        ROW_NUMBER() OVER (ORDER BY d.total_spent DESC) AS rank
    FROM 
        CustomerOrderDetails d
    JOIN 
        customer c ON d.c_custkey = c.c_custkey
    WHERE 
        d.total_spent IS NOT NULL
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_suppkey
),
FinalDetails AS (
    SELECT 
        tc.c_name AS customer_name,
        tc.total_orders,
        tc.total_spent,
        ps.p_name AS part_name,
        ps.total_available,
        ps.avg_supply_cost,
        CASE 
            WHEN ps.total_available IS NULL THEN 'Unavailable' 
            ELSE 'Available' 
        END AS availability_status,
        RANK() OVER (PARTITION BY tc.c_custkey ORDER BY ps.avg_supply_cost DESC) AS part_rank
    FROM 
        TopCustomers tc
    LEFT JOIN 
        PartSupplierDetails ps ON tc.c_custkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey LIMIT 1)
)
SELECT 
    fd.customer_name,
    fd.total_orders,
    fd.total_spent,
    fd.part_name,
    fd.total_available,
    fd.avg_supply_cost,
    fd.availability_status
FROM 
    FinalDetails fd
WHERE 
    fd.part_rank <= 5
ORDER BY 
    fd.customer_name, fd.part_name;
