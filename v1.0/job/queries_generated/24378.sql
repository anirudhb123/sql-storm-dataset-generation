WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
movies_with_keywords_status AS (
    SELECT 
        mwk.movie_id,
        mwk.keywords,
        CASE 
            WHEN COUNT(DISTINCT mwk.keywords) > 3 THEN 'Popular'
            WHEN COUNT(DISTINCT mwk.keywords) BETWEEN 1 AND 3 THEN 'Standard'
            ELSE 'Unknown' 
        END AS popularity_status
    FROM 
        movies_with_keywords mwk
    GROUP BY 
        mwk.movie_id
)
SELECT 
    ak.name,
    rt.title,
    rt.production_year,
    ac.movie_count,
    mwks.keywords,
    mwks.popularity_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    ranked_titles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    actor_movie_counts ac ON ak.person_id = ac.person_id
LEFT JOIN 
    movies_with_keywords_status mwks ON rt.title_id = mwks.movie_id
WHERE 
    ak.name IS NOT NULL
    AND rt.production_year > 1990
    AND (mwks.popularity_status = 'Popular' OR mwks.popularity_status IS NULL)
ORDER BY 
    rt.production_year DESC,
    ak.name ASC
LIMIT 100;
