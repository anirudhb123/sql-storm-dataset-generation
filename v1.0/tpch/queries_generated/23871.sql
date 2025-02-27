WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 0
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_availqty
),
MoneyBackPromotions AS (
    SELECT
        c.c_custkey,
        CASE 
            WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 THEN 'Eligible'
            ELSE 'Not Eligible'
        END AS promotion_status
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ct.total_spent,
        RANK() OVER (ORDER BY ct.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderTotals ct
    JOIN 
        customer c ON ct.c_custkey = c.c_custkey
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        r.r_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        s.s_suppkey, r.r_name
)
SELECT 
    c.c_name AS customer_name,
    p.p_name AS part_name,
    ss.total_supply_cost,
    sr.r_name AS supplier_region,
    rc.supplier_rank,
    t.total_spent AS customer_total_spent,
    pb.promotion_status
FROM 
    PartSupplierDetails ss
JOIN 
    TopCustomers t ON t.custkey IN (SELECT c_custkey FROM CustomerOrderTotals) 
LEFT JOIN 
    RankedSuppliers rc ON rc.s_suppkey = (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey = ss.p_partkey LIMIT 1)
LEFT JOIN 
    MoneyBackPromotions pb ON pb.c_custkey = t.c_custkey
WHERE 
    ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartSupplierDetails)
    AND rc.supplier_rank < 5
ORDER BY 
    customer_total_spent DESC, supplier_region, part_name;
