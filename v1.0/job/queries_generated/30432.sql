WITH RECURSIVE ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_order
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(GROUP_CONCAT(DISTINCT c.person_id), 'No Cast') AS cast_members,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS movie_era
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
filtered_movies AS (
    SELECT 
        *
    FROM 
        movie_details 
    WHERE 
        keyword_count > 3
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.cast_members,
    f.keyword_count,
    f.company_names,
    f.movie_era,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = f.movie_id AND mi.info_type_id IN 
        (SELECT id FROM info_type WHERE info = 'Duration')) AS duration_available,
    (SELECT MIN(r.rank_order)
     FROM ranked_movies r
     WHERE r.movie_id = f.movie_id) AS minimum_rank
FROM 
    filtered_movies f
ORDER BY 
    f.production_year DESC, f.keyword_count DESC;
