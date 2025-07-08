WITH movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        t.kind AS movie_kind,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        kind_type t ON m.kind_id = t.id
    WHERE 
        m.production_year >= 2000 AND m.production_year < 2023
    GROUP BY 
        m.id, m.title, t.kind, m.production_year
),

keyword_aggregate AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    mc.movie_id,
    mc.movie_title,
    mc.cast_names,
    mc.movie_kind,
    mc.production_year,
    mc.num_cast_members,
    ka.keywords
FROM 
    movie_cast mc
LEFT JOIN 
    keyword_aggregate ka ON mc.movie_id = ka.movie_id
ORDER BY 
    mc.production_year DESC,
    mc.num_cast_members DESC;
