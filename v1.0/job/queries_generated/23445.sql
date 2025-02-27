WITH RecursiveMovieCTE AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        c.name AS company_name,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.id) AS company_order
    FROM
        aka_title m
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        name p
    JOIN cast_info ci ON p.id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id, p.name, r.role
),
GenreKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    r.movie_title,
    r.production_year,
    ar.actor_name,
    ar.role_name,
    COALESCE(ekd.keywords, 'No Keywords') AS keywords_info,
    r.company_name,
    CASE 
        WHEN ar.movie_count > 5 THEN 'Prolific Actor'
        WHEN ar.movie_count BETWEEN 3 AND 5 THEN 'Moderately Active Actor'
        ELSE 'Newcomer Actor'
    END AS actor_status,
    (SELECT COUNT(*) 
     FROM cast_info ci2 
     WHERE ci2.movie_id = r.movie_id 
       AND ci2.note IS NOT NULL) AS total_cast_with_notes
FROM 
    RecursiveMovieCTE r
JOIN 
    ActorRoles ar ON r.movie_id = ar.movie_id
LEFT JOIN 
    GenreKeywords ekd ON r.movie_id = ekd.movie_id
WHERE 
    r.company_name IS NOT NULL
    AND (ar.role_name LIKE 'Director%' OR ar.role_name LIKE '%Producer%')
ORDER BY 
    r.production_year DESC, 
    r.movie_title ASC, 
    ar.movie_count DESC;
This query makes use of several advanced SQL constructs and techniques, including:

1. **Common Table Expressions (CTEs)**: Three separate CTEs (`RecursiveMovieCTE`, `ActorRoles`, and `GenreKeywords`) to encapsulate logic for movie data, actor roles, and movie keywords.
  
2. **Window Functions**: The `ROW_NUMBER()` function is used to order companies for each movie.

3. **LEFT JOINs**: Outer joins are used to ensure that all movies are returned even if they don't have any associated companies or keywords.

4. **STRING_AGG()**: This aggregate function concatenates keywords for each movie into a single string, handling NULLs gracefully.

5. **CASE Logic**: The query classifies actors based on their activity in movies using conditional logic.

6. **Correlated Subquery**: A subquery counts the number of cast members who have notes for each movie.

Overall, it provides a rich output that could help in performance benchmarking while showcasing multiple SQL features.
