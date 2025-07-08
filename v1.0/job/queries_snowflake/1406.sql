
WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_characteristics AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(mi.info) AS note_info
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        movie_companies mc ON mi.movie_id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')
    GROUP BY 
        mi.movie_id
),
detailed_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),
final_output AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        m.keyword_count,
        m.cast_count,
        d.actor_name,
        d.role_name,
        COALESCE(m.note_info, 'No Info') AS note_info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_characteristics m ON rm.title_id = m.movie_id
    LEFT JOIN 
        detailed_cast d ON rm.title_id = d.movie_id
    WHERE 
        rm.rank <= 5
)

SELECT 
    *
FROM 
    final_output
WHERE 
    role_name IS NOT NULL

UNION ALL

SELECT 
    title_id, 
    title, 
    production_year, 
    NULL AS keyword_count, 
    NULL AS cast_count, 
    NULL AS actor_name, 
    NULL AS role_name, 
    note_info 
FROM 
    final_output 
WHERE 
    actor_name IS NULL
ORDER BY 
    production_year DESC, 
    title_id;
