
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        t.kind AS movie_kind,
        COALESCE(ARRAY_AGG(DISTINCT ak.name) FILTER (WHERE ak.name IS NOT NULL), ARRAY[]::varchar[]) AS aka_names,
        COALESCE(ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL), ARRAY[]::varchar[]) AS keywords,
        COALESCE(ARRAY_AGG(DISTINCT c.role_id) FILTER (WHERE c.role_id IS NOT NULL), ARRAY[]::int[]) AS roles,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.id
    LEFT JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        kind_type t ON t.id = m.kind_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, t.kind, m.production_year
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.movie_kind,
    rm.aka_names,
    rm.keywords,
    rm.roles
FROM 
    ranked_movies rm
WHERE 
    rm.rn <= 5  
ORDER BY 
    rm.movie_id;
