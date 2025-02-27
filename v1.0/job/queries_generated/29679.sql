WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name an ON c.person_id = an.person_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mt.info, '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type mt ON mi.info_type_id = mt.id
    GROUP BY 
        mi.movie_id
),
final_benchmark AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.kind_id,
        rm.actor_count,
        rm.actor_names,
        ks.keywords,
        mis.info_details
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_summary ks ON rm.id = ks.movie_id
    LEFT JOIN 
        movie_info_summary mis ON rm.id = mis.movie_id
)
SELECT 
    fb.movie_title,
    fb.production_year,
    fb.kind_id,
    fb.actor_count,
    fb.actor_names,
    COALESCE(fb.keywords, 'No keywords') AS keywords,
    COALESCE(fb.info_details, 'No additional info') AS info
FROM 
    final_benchmark fb
ORDER BY 
    fb.production_year DESC, 
    fb.actor_count DESC;
