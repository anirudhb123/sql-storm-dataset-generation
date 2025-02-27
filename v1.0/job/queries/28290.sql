WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        mr.role,
        mr.role_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.id
    JOIN 
        MovieRoles mr ON t.id = mr.movie_id
),
KeywordDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.role,
    md.role_count,
    kd.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.title;
