WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
movie_info_combined AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No information available') AS movie_info,
        CASE 
            WHEN mi.note IS NULL THEN 'No note provided'
            ELSE mi.note 
        END AS info_note
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year >= 2000
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_output AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        cd.actor_name,
        cd.role_name,
        mi.movie_info,
        mi.info_note,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_details cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        movie_info_combined mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        keyword_count kc ON rm.movie_id = kc.movie_id
    WHERE 
        cd.nr_order = 1 OR cd.nr_order IS NULL
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    STRING_AGG(f.actor_name, ', ') AS lead_actors,
    COUNT(f.role_name) AS total_roles,
    AVG(f.keyword_count) AS avg_keyword_count
FROM 
    final_output f
GROUP BY 
    f.movie_id, f.movie_title, f.production_year
HAVING 
    AVG(f.keyword_count) > 0 OR COUNT(f.role_name) > 2
ORDER BY 
    f.production_year DESC, f.movie_title
FETCH FIRST 10 ROWS ONLY;
