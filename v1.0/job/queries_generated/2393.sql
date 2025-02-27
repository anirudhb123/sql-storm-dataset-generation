WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COALESCE(kw.keyword, 'No Keywords') AS keyword,
        COUNT(cc.person_id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON at.movie_id = cc.movie_id
    GROUP BY 
        at.id, at.title, at.production_year, kw.keyword
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.year_rank <= 5
),
actor_info AS (
    SELECT 
        ak.name,
        ac.movie_id,
        ac.role_id,
        rt.role
    FROM 
        aka_name ak
    JOIN 
        cast_info ac ON ak.person_id = ac.person_id
    JOIN 
        role_type rt ON ac.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    fm.title,
    fm.production_year,
    COUNT(DISTINCT ai.name) AS unique_actors,
    STRING_AGG(DISTINCT ai.role, ', ') AS roles,
    CASE 
        WHEN SUM(fm.cast_count) IS NULL THEN 'No Cast'
        ELSE SUM(fm.cast_count)::text
    END AS total_cast_count
FROM 
    filtered_movies fm
LEFT JOIN 
    actor_info ai ON fm.movie_id = ai.movie_id
GROUP BY 
    fm.title, fm.production_year
HAVING 
    COUNT(DISTINCT ai.name) > 0
ORDER BY 
    fm.production_year DESC, unique_actors DESC;
