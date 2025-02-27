WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
movie_cast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        ranked_titles rt ON cc.movie_id = rt.title_id
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    mk.keyword_count,
    mc.num_cast,
    mc.cast_names,
    COALESCE(NULLIF(mk.keyword_count, 0), 'No Keywords') AS keyword_info
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_cast mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.production_year > 2000
    AND rt.title LIKE 'A%'
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
