WITH RegionalSuppliers AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(s.s_acctbal) AS avg_acct_bal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name, s.s_suppkey, s.s_name
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
        o.o_orderstatus = 'O' AND o.o_totalprice > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.nation_name, 
    r.region_name, 
    r.s_name, 
    COALESCE(hvc.total_spent, 0) AS total_spent_by_high_value_customer,
    os.item_count,
    os.total_line_price,
    ROW_NUMBER() OVER (PARTITION BY r.region_name ORDER BY os.total_line_price DESC) AS rank
FROM 
    RegionalSuppliers r
LEFT JOIN 
    HighValueCustomers hvc ON r.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_custkey = hvc.c_custkey 
    )
LEFT JOIN 
    OrderStats os ON r.total_avail_qty > 0 
WHERE 
    r.total_avail_qty IS NOT NULL
ORDER BY 
    r.region_name, rank;
