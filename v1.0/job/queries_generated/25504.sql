WITH movie_with_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        c.person_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT r.role ORDER BY r.id) AS roles,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
        AND a.name IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year, c.person_id, a.name
),
movie_with_keywords AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.actor_name,
        mwc.roles,
        mwc.cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_with_cast mwc
    JOIN 
        movie_keyword mk ON mwc.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mwc.movie_id, mwc.title, mwc.production_year, mwc.actor_name, mwc.roles, mwc.cast_count
),
final_result AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.actor_name,
        mwk.roles,
        mwk.cast_count,
        k.kind AS movie_kind,
        COUNT(m.id) AS total_info_entries
    FROM 
        movie_with_keywords mwk
    LEFT JOIN 
        movie_info m ON mwk.movie_id = m.movie_id
    LEFT JOIN 
        kind_type k ON m.info_type_id = k.id
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year, mwk.actor_name, mwk.roles, mwk.cast_count, k.kind
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    roles,
    cast_count,
    movie_kind,
    total_info_entries
FROM 
    final_result
ORDER BY 
    production_year DESC, cast_count DESC;

