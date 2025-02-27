WITH RankedOrders AS (
  SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
  FROM 
    orders o
  WHERE 
    o.o_orderstatus IN ('O', 'F')
),
AggregatedSupplierCosts AS (
  SELECT 
    ps.ps_suppkey,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
  FROM 
    partsupp ps
  GROUP BY 
    ps.ps_suppkey
),
FilteredParts AS (
  SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    CASE 
      WHEN p.p_container IS NULL THEN 'Unknown Container'
      ELSE p.p_container
    END AS container_type
  FROM 
    part p
  WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerNation AS (
  SELECT 
    c.c_custkey,
    n.n_name AS nation_name,
    c.c_acctbal,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS cust_rank
  FROM 
    customer c
  JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
  WHERE 
    c.c_acctbal IS NOT NULL
)
SELECT 
  fn.nation_name,
  COUNT(DISTINCT fo.o_orderkey) AS total_orders,
  SUM(fo.total_supply_cost) AS total_costs,
  AVG(fp.p_retailprice) AS avg_part_retail_price,
  COUNT(DISTINCT CASE WHEN li.l_returnflag = 'R' THEN li.l_orderkey ELSE NULL END) AS returned_orders,
  STRING_AGG(DISTINCT fp.p_name, ', ') AS popular_parts
FROM 
  CustomerNation fn
LEFT JOIN 
  RankedOrders fo ON fn.c_custkey = fo.o_orderkey
LEFT JOIN 
  AggregatedSupplierCosts fsc ON fsc.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT MAX(fp.p_partkey) FROM FilteredParts fp WHERE fp.container_type = 'Unknown Container'))
LEFT JOIN 
  lineitem li ON li.l_orderkey = fo.o_orderkey
GROUP BY 
  fn.nation_name
HAVING 
  SUM(fo.total_supply_cost) > (
    SELECT AVG(total_supply_cost) FROM AggregatedSupplierCosts
  )
ORDER BY 
  total_orders DESC, 
  total_costs DESC 
LIMIT 10;
