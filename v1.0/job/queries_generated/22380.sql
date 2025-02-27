WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title, 
        title.production_year,
        RANK() OVER (PARTITION BY title.kind_id ORDER BY title.production_year DESC) AS movie_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        cast_info.movie_id, 
        aka_name.name AS actor_name, 
        COUNT(cast_info.person_id) OVER (PARTITION BY cast_info.movie_id) AS actor_count
    FROM 
        cast_info
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        aka_name.name IS NOT NULL
),
movies_with_keyword AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
movie_awards AS (
    SELECT 
        movie_info.movie_id,
        MAX(CASE WHEN info_type.info = 'Oscar' THEN movie_info.info END) AS oscar_count,
        MAX(CASE WHEN info_type.info = 'Golden Globe' THEN movie_info.info END) AS golden_globe_count
    FROM 
        movie_info
    JOIN 
        info_type ON movie_info.info_type_id = info_type.id
    GROUP BY 
        movie_info.movie_id
)
SELECT 
    rm.movie_id,
    rm.title AS movie_title,
    rm.production_year,
    cd.actor_name,
    cd.actor_count,
    mwk.keywords,
    ma.oscar_count,
    ma.golden_globe_count
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movies_with_keyword mwk ON rm.movie_id = mwk.movie_id
LEFT JOIN 
    movie_awards ma ON rm.movie_id = ma.movie_id
WHERE 
    rm.movie_rank <= 5
    AND (ma.oscar_count IS NOT NULL OR ma.golden_globe_count IS NOT NULL) -- Movies with at least one award
ORDER BY 
    rm.production_year DESC, 
    cd.actor_count DESC NULLS LAST;

