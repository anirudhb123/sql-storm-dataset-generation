WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank,
        RANK() OVER (ORDER BY o.o_totalprice DESC) as total_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) as unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerPurchases AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    AVG(COALESCE(cd.total_spent, 0)) AS avg_spent_per_customer,
    MAX(sd.total_supply_cost) AS max_supply_cost_per_supplier,
    SUM(CASE 
            WHEN cd.order_count IS NULL THEN 1 ELSE 0 
        END) AS non_ordering_customers
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerPurchases cd ON n.n_nationkey = cd.c_nationkey
LEFT JOIN 
    SupplierDetails sd ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = sd.s_suppkey OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) >= 2
ORDER BY 
    r.r_name ASC, avg_spent_per_customer DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
