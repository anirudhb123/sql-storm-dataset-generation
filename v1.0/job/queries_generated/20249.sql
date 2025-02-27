WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank_by_year
    FROM 
        aka_title a 
    WHERE 
        a.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(c.person_id, -1) AS actor_id, -- use -1 for movies with no cast
        c.nr_order,
        CASE WHEN c.nr_order IS NULL THEN 'No Cast' ELSE 'Has Cast' END AS cast_status
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
),
info_counter AS (
    SELECT 
        movie_id,
        COUNT(*) AS info_count
    FROM 
        movie_info 
    GROUP BY 
        movie_id
),
keyword_data AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
combined_data AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        mc.actor_id,
        mc.cast_status,
        COALESCE(ic.info_count, 0) AS movie_info_count,
        COALESCE(kd.keywords, 'No Keywords') AS keywords
    FROM 
        movie_cast mc
    JOIN 
        ranked_titles t ON mc.movie_id = t.id
    LEFT JOIN 
        info_counter ic ON mc.movie_id = ic.movie_id
    LEFT JOIN 
        keyword_data kd ON mc.movie_id = kd.movie_id
)
SELECT 
    cd.production_year,
    COUNT(*) AS total_movies,
    AVG(cd.movie_info_count) AS average_info_per_movie,
    STRING_AGG(DISTINCT cd.keywords, '; ') AS all_keywords,
    COUNT(DISTINCT cd.actor_id) FILTER (WHERE cd.cast_status = 'Has Cast') AS actors_with_roles
FROM 
    combined_data cd
WHERE 
    cd.rank_by_year <= 5 -- to focus on films within the top N per year
GROUP BY 
    cd.production_year
ORDER BY 
    cd.production_year DESC;
