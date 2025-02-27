WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id
    FROM 
        title t
    JOIN 
        movie_link ml ON ml.linked_movie_id = MovieHierarchy.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT mko.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword mko ON mk.keyword_id = mko.id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_title, mh.production_year, a.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 5
ORDER BY 
    mh.production_year, rank_by_company;
In this SQL query:

1. **Recursive CTE** `MovieHierarchy` builds a hierarchy of movies, starting from those produced after the year 2000 and including their linked movies.
2. The main query selects the movie titles, their production years, the actor’s names, the count of production companies associated with each movie, and accumulates keywords in a comma-separated format.
3. `RANK()` is utilized to rank movies based on the number of associated companies.
4. `LEFT JOIN` ensures that even if there is no associated actor or company, the movie will still be included in the results.
5. `HAVING` filters the results to include only those movies associated with more than 5 companies.
6. Finally, the results are ordered by production year and the rank of each movie.
