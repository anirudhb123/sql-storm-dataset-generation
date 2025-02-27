WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.kind_id, 
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
movie_keyword_count AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
movie_info_summary AS (
    SELECT 
        i.movie_id, 
        STRING_AGG(DISTINCT info.info, ', ') AS aggregated_info
    FROM 
        movie_info i
    LEFT JOIN 
        info_type it ON i.info_type_id = it.id
    WHERE 
        it.info LIKE '%Box Office%'
    GROUP BY 
        i.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.num_cast_members, 
    COALESCE(mk.total_keywords, 0) AS keyword_count,
    mi.aggregated_info
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keyword_count mk ON rm.id = mk.movie_id
LEFT JOIN 
    movie_info_summary mi ON rm.id = mi.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast_members DESC;
