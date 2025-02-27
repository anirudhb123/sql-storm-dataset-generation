WITH RECURSIVE actor_hierarchy AS (
    SELECT
        c.person_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM
        cast_info c
    INNER JOIN
        aka_name ak ON c.person_id = ak.person_id
    INNER JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
top_actors AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        AVG(production_year) AS avg_year
    FROM 
        actor_hierarchy
    WHERE 
        movie_rank <= 5
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 2
),
actor_keywords AS (
    SELECT
        ak.name AS actor_name,
        k.keyword AS keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM
        aka_name ak
    LEFT JOIN
        cast_info c ON ak.person_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ak.name, k.keyword
),
final_output AS (
    SELECT 
        ta.actor_name,
        ta.movie_count,
        ta.avg_year,
        ak.keyword,
        ak.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY ta.actor_name ORDER BY ak.keyword_count DESC NULLS LAST) AS keyword_rank
    FROM 
        top_actors ta
    LEFT JOIN 
        actor_keywords ak ON ta.actor_name = ak.actor_name
)
SELECT 
    fo.actor_name,
    fo.movie_count,
    fo.avg_year,
    COALESCE(STRING_AGG(fo.keyword, ', ' ORDER BY fo.keyword_rank), 'No Keywords') AS keywords,
    CASE 
        WHEN fo.movie_count IS NULL THEN 'No Movies'
        WHEN fo.avg_year < 2000 THEN 'Classic Actor'
        ELSE 'Contemporary Actor'
    END AS actor_category,
    NULLIF(AVG(fo.keyword_count) FILTER (WHERE fo.keyword IS NOT NULL), 0) AS avg_keyword_count
FROM 
    final_output fo
GROUP BY 
    fo.actor_name, fo.movie_count, fo.avg_year
ORDER BY 
    movie_count DESC, avg_year ASC
FETCH FIRST 10 ROWS ONLY;
