WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    an.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    ak.keywords,
    ac.movie_count,
    COALESCE(rt.rank_year, 100) AS title_rank
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    ranked_titles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    movies_with_keywords ak ON rt.title_id = ak.movie_id
JOIN 
    actor_movie_count ac ON an.person_id = ac.person_id
WHERE 
    an.name IS NOT NULL
    AND rt.production_year > 2000
    AND ac.movie_count > 5
ORDER BY 
    rt.production_year DESC, title_rank ASC;
