
WITH RankedTitles AS (
  SELECT 
    at.id AS title_id, 
    at.title, 
    at.production_year,
    RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
  FROM 
    aka_title at
),
CastInfoAggregated AS (
  SELECT 
    c.movie_id,
    COUNT(DISTINCT c.person_id) AS actor_count,
    LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
    MAX(ct.kind) AS primary_role
  FROM 
    cast_info c
  JOIN 
    aka_name a ON c.person_id = a.person_id
  LEFT JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
  GROUP BY 
    c.movie_id
),
MovieKeywordCounts AS (
  SELECT 
    mk.movie_id, 
    COUNT(mk.keyword_id) AS keyword_count
  FROM 
    movie_keyword mk
  GROUP BY 
    mk.movie_id
),
MostKeywords AS (
  SELECT 
    movie_id 
  FROM 
    MovieKeywordCounts
  WHERE 
    keyword_count = (SELECT MAX(keyword_count) FROM MovieKeywordCounts)
)
SELECT 
  rt.title AS Movie_Title, 
  rt.production_year AS Year_Produced, 
  cia.actor_count AS Number_of_Actors,
  cia.actor_names AS Actor_Names,
  COALESCE(ctt.kind, 'Unknown') AS Cast_Type,
  CASE 
    WHEN rt.title_rank IS NULL THEN 'Not Ranked'
    ELSE CAST(rt.title_rank AS VARCHAR)
  END AS Title_Rank,
  MISSING_INFO.info AS Missing_Title_Info
FROM 
  RankedTitles rt
JOIN 
  CastInfoAggregated cia ON rt.title_id = cia.movie_id
LEFT JOIN 
  comp_cast_type ctt ON ctt.kind = cia.primary_role
LEFT JOIN 
  (SELECT 
     movie_id, 
     info 
   FROM 
     movie_info 
   WHERE 
     info IS NOT NULL AND note IS NOT NULL) MISSING_INFO 
  ON rt.title_id = MISSING_INFO.movie_id
WHERE 
  rt.production_year >= 2000
  AND rt.title_id IN (SELECT movie_id FROM MostKeywords)
ORDER BY 
  rt.production_year DESC, 
  cia.actor_count DESC;
