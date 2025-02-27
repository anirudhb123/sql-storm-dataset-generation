WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_keyword_cte AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) OVER (PARTITION BY mk.movie_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.rank_by_title,
    m.total_movies,
    COALESCE(cd.distinct_cast_count, 0) AS distinct_cast_count,
    COALESCE(cd.actors_names, 'No cast available') AS actors_names,
    COALESCE(mkc.keyword, 'No keywords') AS keywords,
    mkc.keyword_count
FROM 
    ranked_movies m
LEFT JOIN 
    cast_details cd ON m.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword_cte mkc ON m.movie_id = mkc.movie_id
WHERE 
    m.rank_by_title <= 5 
    AND (m.production_year < 2000 OR mkc.keyword_count IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    m.rank_by_title ASC;

-- Additionally testing corner cases with NULL logic and unusual joins
SELECT 
    m.id AS movie_id,
    t.title,
    COALESCE(ca.actors_names, 'Unknown Actor') AS actor_names
FROM 
    aka_title t 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id OR cn.id IS NULL
LEFT JOIN 
    (SELECT 
         ci.movie_id,
         STRING_AGG(DISTINCT ak.name, ', ') AS actors_names
     FROM 
         cast_info ci
     JOIN 
         aka_name ak ON ci.person_id = ak.person_id
     GROUP BY 
         ci.movie_id
    ) ca ON t.id = ca.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'm%') 
    AND (cn.country_code IS NULL OR cn.country_code = 'USA')
ORDER BY 
    COALESCE(t.production_year, 0) ASC, 
    character_length(t.title) DESC;
