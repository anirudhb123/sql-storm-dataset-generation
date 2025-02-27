WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
)
SELECT 
    cs.c_custkey,
    cs.total_spent,
    cs.order_count,
    COALESCE(RA.total_revenue, 0) AS total_revenue,
    COALESCE(SPI.total_supply_cost, 0) AS total_supply_cost
FROM 
    CustomerSummary cs
LEFT JOIN (
    SELECT 
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        o.o_custkey
) RA ON cs.c_custkey = RA.o_custkey
FULL OUTER JOIN SupplierPartInfo SPI ON cs.total_spent > SPI.total_supply_cost
WHERE 
    cs.order_count > 5
ORDER BY 
    cs.total_spent DESC, cs.order_count DESC;
