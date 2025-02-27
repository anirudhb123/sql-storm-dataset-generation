WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    m.title AS Movie,
    m.production_year AS Production_Year,
    COALESCE(cast_person.name, 'Unknown') AS Cast_Person,
    COALESCE(comp.name, 'Independent') AS Company_Name,
    COUNT(DISTINCT k.keyword) AS Total_Keywords,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS Keyword_Rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name cast_person ON ci.person_id = cast_person.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.level = 1
    AND (m.production_year BETWEEN 2000 AND 2023)
    AND (comp.country_code IS NULL OR comp.country_code = 'USA')
GROUP BY 
    m.movie_id, 
    m.title, 
    m.production_year, 
    cast_person.name, 
    comp.name
ORDER BY 
    m.production_year DESC, 
    Keyword_Rank;

### Explanation:
- **Recursive CTE (MovieHierarchy)**: Builds a hierarchy of movies based on linked movies, starting with titles that have valid production years.
  
- **Select Statement**: Collects various information:
  - Movie title and production year from the hierarchy.
  - Cast person names using `COALESCE` to handle potential NULL values.
  - Company names, also managing NULL cases if a movie is independent.
  - Uses a `LEFT JOIN` to acquire keywords associated with each movie.

- **Calculations**:
  - Counts distinct keywords for each movie to give an idea of the movie's categorization or themes.

- **Window Function**: `ROW_NUMBER()` to rank movies based on the count of keywords per production year.

- **Filtering & Grouping**: 
  - Filters results for movies produced between 2000 and 2023.
  - Includes NULL logic for companies by checking the country code.
  
- **Order By**: Results are ordered by production year descending and then by keyword rank.
