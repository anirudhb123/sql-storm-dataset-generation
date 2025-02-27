WITH movie_title_stats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS total_info,
        AVG(CASE WHEN mi.info_type_id = 2 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ranked_movies AS (
    SELECT 
        mts.*,
        kc.keyword_count,
        RANK() OVER (ORDER BY mts.actor_count DESC, mts.company_count ASC) AS rank_desc
    FROM 
        movie_title_stats mts
    LEFT JOIN 
        keyword_counts kc ON mts.title_id = kc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.company_count,
    COALESCE(rm.keyword_count, 0) AS keyword_count,
    rm.avg_info_length,
    CASE 
        WHEN rm.actor_count > 10 THEN 'Large Cast'
        WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        WHEN rm.actor_count < 5 THEN 'Small Cast'
        ELSE 'No Cast Info'
    END AS cast_category
FROM 
    ranked_movies rm
WHERE 
    rm.rank_desc <= 10
ORDER BY 
    rm.rank_desc;
