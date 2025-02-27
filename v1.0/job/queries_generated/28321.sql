WITH movie_info_aggregated AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT ki.kind) AS keyword_kinds,
        ARRAY_AGG(DISTINCT it.info) AS movie_infos
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mi.movie_id = m.id
    GROUP BY 
        m.movie_id
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_details
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movies_with_details AS (
    SELECT 
        t.title,
        t.production_year,
        mia.keyword_kinds,
        c.actor_count,
        c.cast_details
    FROM 
        title t
    LEFT JOIN 
        movie_info_aggregated mia ON t.id = mia.movie_id
    LEFT JOIN 
        cast_info_summary c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
)

SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.keyword_kinds, '{}'::text[]) AS keywords,
    COALESCE(mw.actor_count, 0) AS total_actors,
    COALESCE(mw.cast_details, 'No cast info available') AS cast_info
FROM 
    movies_with_details mw
ORDER BY 
    mw.production_year DESC, mw.title;
