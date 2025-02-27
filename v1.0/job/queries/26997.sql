WITH movie_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        MAX(t.production_year) AS latest_year,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title
), 
company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
full_movie_info AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.cast_count,
        ms.actor_names,
        ms.latest_year,
        ms.keyword_count,
        COALESCE(ci.company_count, 0) AS company_count,
        COALESCE(ci.company_names, 'None') AS company_names
    FROM 
        movie_stats ms
    LEFT JOIN 
        company_info ci ON ms.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    cast_count,
    ARRAY_TO_STRING(actor_names, ', ') AS actors,
    latest_year,
    keyword_count,
    company_count,
    company_names
FROM 
    full_movie_info
WHERE 
    cast_count > 0
ORDER BY 
    latest_year DESC, 
    cast_count DESC;
