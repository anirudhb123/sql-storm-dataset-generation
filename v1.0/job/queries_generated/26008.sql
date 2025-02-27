WITH
  movie_details AS (
    SELECT 
      m.id AS movie_id,
      m.title,
      m.production_year,
      GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_names,
      GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
      GROUP_CONCAT(DISTINCT company.name ORDER BY company.name SEPARATOR ', ') AS companies
    FROM 
      aka_title m
    JOIN 
      complete_cast cc ON m.id = cc.movie_id
    JOIN 
      cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
      aka_name c ON ci.person_id = c.person_id
    JOIN 
      movie_keyword mk ON m.id = mk.movie_id
    JOIN 
      keyword k ON mk.keyword_id = k.id
    JOIN 
      movie_companies mc ON m.id = mc.movie_id
    JOIN 
      company_name company ON mc.company_id = company.id
    WHERE 
      m.production_year >= 2000
    GROUP BY 
      m.id
  ),
  unique_cast AS (
    SELECT 
      DISTINCT movie_id, 
      CAST(COUNT(DISTINCT cast_names) AS INTEGER) AS distinct_cast_count
    FROM 
      movie_details
    GROUP BY 
      movie_id
  ),
  movie_analysis AS (
    SELECT 
      md.movie_id,
      md.title,
      md.production_year,
      uc.distinct_cast_count,
      LENGTH(md.keywords) - LENGTH(REPLACE(md.keywords, ',', '')) + 1 AS keyword_count
    FROM 
      movie_details md
    JOIN 
      unique_cast uc ON md.movie_id = uc.movie_id
  )
SELECT 
  *,
  CASE 
    WHEN distinct_cast_count > 5 AND keyword_count > 3 THEN 'Highly Collaborative'
    WHEN distinct_cast_count BETWEEN 3 AND 5 AND keyword_count BETWEEN 2 AND 3 THEN 'Moderately Collaborative'
    ELSE 'Less Collaborative'
  END AS collaboration_level
FROM 
  movie_analysis
ORDER BY 
  production_year DESC, 
  title;
