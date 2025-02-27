WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        LEAD(o.o_totalprice) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS next_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
),
SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
RankingSubquery AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    sp.s_name,
    sp.total_available_qty,
    r.p_name,
    r.total_sales,
    sct.effective_order_value,
    sct.o_orderdate
FROM 
    SupplierPart sp
FULL OUTER JOIN 
    (SELECT 
         r.p_name,
         r.total_sales,
         r.sales_rank,
         CASE 
             WHEN r.sales_rank <= 10 THEN 'Top 10'
             ELSE 'Others'
         END AS sales_category
     FROM 
         RankingSubquery r) AS ranked ON sp.ps_partkey = r.p_partkey
LEFT JOIN 
    (SELECT 
         sc.custkey,
         AVG(sc.next_order_value - sc.o_totalprice) AS effective_order_value,
         sc.o_orderdate
     FROM 
         SalesCTE sc
     GROUP BY 
         sc.custkey, sc.o_orderdate) AS sct ON sp.s_suppkey = sct.custkey
WHERE 
    sp.total_available_qty IS NOT NULL AND 
    (r.total_sales > 10000 OR r.sales_rank = 1)
ORDER BY 
    sp.total_available_qty DESC, r.total_sales DESC;
