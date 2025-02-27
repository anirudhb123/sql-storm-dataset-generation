WITH movie_titles AS (
  SELECT 
    t.id AS title_id,
    t.title,
    t.production_year,
    t.kind_id,
    k.keyword AS movie_keyword,
    ARRAY_AGG(DISTINCT cn.name) AS company_names,
    ARRAY_AGG(DISTINCT r.role) AS roles,
    ARRAY_AGG(DISTINCT COALESCE(an.name, 'Unknown')) AS actors
  FROM 
    title t
  LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
  LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
  LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
  LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
  LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
  LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
  LEFT JOIN 
    role_type r ON ci.role_id = r.id 
  LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
  WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
  GROUP BY 
    t.id, t.title, t.production_year, t.kind_id
)
SELECT 
  title_id,
  title,
  production_year,
  kind_id,
  STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
  STRING_AGG(DISTINCT company_names, ', ') AS companies,
  STRING_AGG(DISTINCT roles, ', ') AS roles,
  STRING_AGG(DISTINCT actors, ', ') AS cast
FROM 
  movie_titles
GROUP BY 
  title_id, title, production_year, kind_id
ORDER BY 
  production_year DESC, title;
