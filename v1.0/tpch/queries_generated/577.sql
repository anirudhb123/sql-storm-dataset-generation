WITH Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Customer_Rank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Lineitem_Details AS (
    SELECT 
        l.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_shipdate,
        LEAD(l.l_shipdate) OVER (PARTITION BY l.o_orderkey ORDER BY l.l_linenumber) AS next_shipdate
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
)
SELECT 
    n.n_name,
    SUM(s.total_cost) AS total_supplier_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(DATEDIFF(day, ld.l_shipdate, ld.next_shipdate)) AS avg_days_between_shipments
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    Supplier_Summary s ON n.n_nationkey = s.s_suppkey
LEFT JOIN 
    Customer_Rank c ON c.cust_rank <= 3
LEFT JOIN 
    Lineitem_Details ld ON ld.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
GROUP BY 
    n.n_name
HAVING 
    SUM(s.total_cost) IS NOT NULL AND 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_supplier_cost DESC;
