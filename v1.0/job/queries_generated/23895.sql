WITH recursive MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS VARCHAR(100)) AS linked_titles,
        mt.kind_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 
    UNION ALL
    SELECT 
        ml.linked_movie_id, 
        mk.title, 
        mk.production_year,
        mh.linked_titles || ', ' || mk.title,
        mk.kind_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS main_movie_title,
    mh.production_year AS production_year,
    mh.linked_titles AS related_movies,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS year_rank,
    COUNT(DISTINCT cc.company_id) FILTER (WHERE ct.kind NOT ILIKE '%production%') AS distribution_companies,
    COALESCE(MAX(cf.name), 'UNKNOWN') AS first_char_name,
    CASE 
        WHEN mh.kind_id IS NULL THEN 'No Kind Info' 
        ELSE 'Has Kind Info'
    END AS kind_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    aka_name p ON pi.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cf ON mc.company_id = cf.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    mh.production_year > 2000 
    AND mh.title IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.kind_id
HAVING 
    COUNT(DISTINCT p.id) > 1 
ORDER BY 
    year_rank, production_year DESC
LIMIT 100;

### Explanation:
- **CTE (MovieHierarchy)**: This recursive CTE generates a hierarchy of movies along with their linked titles by traversing through the `movie_link` table.
- **SELECT Statement**: It selects various columns, including the main movie title, its production year, and related linked titles.
- **STRING_AGG**: This aggregate function concatenates distinct cast names related to the movie.
- **COUNT with FILTER**: It counts the number of distinct distribution companies for each movie, excluding those tagged as production.
- **CASE Statement**: It provides a semantic check for the kind of movie information.
- **ROW_NUMBER**: This window function ranks movies by the number of keywords in descending order within each production year.
- **COALESCE**: It handles potential NULLs when fetching names of companies associated with the movie.
- **HAVING Clause**: Ensures only movies with more than one cast member are considered, indicating some requirement for ensemble.
- **ORDER BY and LIMIT**: The final output is ordered by rank and production year, limiting results to the top 100.
