WITH RECURSIVE OrderedCTE AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderstatus = 'O' AND o_orderdate >= DATE '2021-01-01'
    
    UNION ALL

    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice
    FROM orders o
    JOIN OrderedCTE cte ON o.o_custkey = cte.o_custkey
    WHERE o.o_orderdate > cte.o_orderdate
      AND o.o_orderstatus = 'O'
),
RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    JOIN OrderedCTE o ON l.l_orderkey = o.o_orderkey
    GROUP BY l.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
MaxSupplier AS (
    SELECT 
        s.suppkey,
        s.name,
        s.region_name,
        s.total_available,
        RANK() OVER (ORDER BY s.total_available DESC) AS rnk
    FROM SupplierDetails s
)
SELECT 
    o.o_orderkey,
    c.c_name,
    o.o_orderdate,
    rs.net_sales,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Best Selling'
        ELSE 'Regular'
    END AS sales_category,
    ms.name AS best_supplier
FROM OrderedCTE o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN RankedSales rs ON o.o_orderkey = rs.l_orderkey
LEFT JOIN MaxSupplier ms ON ms.rnk = 1
WHERE o.o_totalprice > 1000
AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
ORDER BY o.o_orderdate DESC, rs.net_sales DESC;
