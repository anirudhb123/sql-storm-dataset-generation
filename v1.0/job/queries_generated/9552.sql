WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_details AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT a.person_id) AS actor_count, 
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_info_extended AS (
    SELECT 
        m.movie_id, 
        mi.info_type_id, 
        mi.info, 
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id, mi.info_type_id, mi.info
),
final_results AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        cd.actor_count, 
        cd.actor_names, 
        mie.info, 
        mie.keyword_count, 
        rt.company_count
    FROM 
        ranked_titles rt
    JOIN 
        cast_details cd ON rt.title_id = cd.movie_id
    JOIN 
        movie_info_extended mie ON rt.title_id = mie.movie_id
    WHERE 
        rt.production_year >= 2000
    ORDER BY 
        rt.production_year DESC, 
        rt.company_count DESC
)
SELECT 
    * 
FROM 
    final_results
LIMIT 
    50;
