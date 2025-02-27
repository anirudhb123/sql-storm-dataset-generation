WITH movie_cast AS (
    SELECT 
        ka.name AS actor_name, 
        ti.title AS movie_title, 
        ti.production_year AS release_year, 
        rt.role AS role,
        COALESCE(ci.note, 'No notes') AS casting_note
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ti.production_year >= 2000
),
keyword_aggregates AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_aggregates AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CONCAT_WS(': ', it.info, mi.info), '; ') AS movie_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
final_results AS (
    SELECT 
        mc.actor_name,
        mc.movie_title,
        mc.release_year,
        mc.role,
        mc.casting_note,
        ka.keywords,
        mia.movie_info
    FROM 
        movie_cast mc
    LEFT JOIN 
        keyword_aggregates ka ON mc.movie_id = ka.movie_id
    LEFT JOIN 
        movie_info_aggregates mia ON mc.movie_title = mia.movie_id
)
SELECT 
    actor_name,
    movie_title,
    release_year,
    role,
    casting_note,
    COALESCE(keywords, 'No keywords') AS keywords,
    COALESCE(movie_info, 'No additional info') AS movie_info
FROM 
    final_results
ORDER BY 
    release_year DESC, actor_name;
