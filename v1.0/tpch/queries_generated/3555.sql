WITH RankedSuppliers AS (
  SELECT 
    s.s_suppkey,
    s.s_name,
    s.s_acctbal,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
  FROM 
    supplier s
),
HighValueParts AS (
  SELECT 
    ps.ps_partkey,
    SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
  FROM 
    partsupp ps
  GROUP BY 
    ps.ps_partkey
  HAVING 
    SUM(ps.ps_availqty * ps.ps_supplycost) > 10000
),
SeasonalSales AS (
  SELECT 
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_total
  FROM 
    orders o
  JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
  WHERE 
    l.l_shipdate BETWEEN DATE '2023-06-01' AND DATE '2023-08-31'
  GROUP BY 
    o.o_orderkey
)
SELECT 
  p.p_name,
  COALESCE(rn.r_name, 'Unknown') AS region,
  SUM(COALESCE(ss.sales_total, 0)) AS total_sales,
  COUNT(DISTINCT hs.s_suppkey) AS supplier_count,
  AVG(hs.s_acctbal) AS avg_account_balance
FROM 
  part p
LEFT JOIN 
  partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
  RankedSuppliers hs ON ps.ps_suppkey = hs.s_suppkey AND hs.rank <= 5
LEFT JOIN 
  supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
  nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
  region rn ON n.n_regionkey = rn.r_regionkey
LEFT JOIN 
  SeasonalSales ss ON p.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = hs.s_suppkey LIMIT 1)
WHERE 
  (p.p_size BETWEEN 10 AND 20 OR p.p_mfgr LIKE 'Manufacturer%')
GROUP BY 
  p.p_name, rn.r_name
HAVING 
  SUM(COALESCE(ss.sales_total, 0)) > 5000
ORDER BY 
  total_sales DESC;
