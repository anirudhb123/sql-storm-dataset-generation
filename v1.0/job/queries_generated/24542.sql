WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rc.production_year,
        COUNT(c.id) AS role_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    LEFT JOIN 
        ranked_movies rc ON c.movie_id = rc.title_id
    GROUP BY 
        c.movie_id, rc.production_year
),
movie_info_details AS (
    SELECT 
        m.movie_id,
        COALESCE(mi.info, 'No Info') AS info,
        COUNT(mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    GROUP BY 
        m.movie_id, mi.info
),
combined_data AS (
    SELECT 
        mc.movie_id,
        mc.actor_name,
        mc.role_count,
        mid.info,
        mid.keyword_count,
        mid.company_count
    FROM 
        movie_cast mc
    FULL OUTER JOIN 
        movie_info_details mid ON mc.movie_id = mid.movie_id
)
SELECT 
    MIN(cd.actor_name) AS first_actor_name,
    MAX(cd.role_count) AS max_roles,
    COUNT(cd.movie_id) AS total_movies,
    SUM(cd.keyword_count) AS total_keywords,
    AVG(NULLIF(cd.company_count, 0)) AS avg_companies_per_movie,
    STRING_AGG(DISTINCT cd.info, '; ') AS unique_infos
FROM 
    combined_data cd
WHERE 
    cd.role_count > 0
GROUP BY 
    cd.actor_name
HAVING 
    COUNT(cd.movie_id) > 5 OR MAX(cd.role_count) > 3
ORDER BY 
    total_movies DESC
OFFSET 1 ROWS
FETCH NEXT 5 ROWS ONLY;

This SQL query generates a rich dataset showcasing relationships between movies, actors, and various attributes such as information and keywords. It integrates several constructs like `WITH` CTE for organizing complex subqueries, `ROW_NUMBER()` for ranking, outer joins for combining datasets even when they do not match, and complex aggregations including `STRING_AGG` and `NULLIF` to handle peculiarities in movie data. The `HAVING` clause emphasizes the flexibility of conditionally filtering results based on aggregated values, leading to an interesting performance benchmark query.
