WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        km.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        a.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id, c.role_id
    HAVING 
        COUNT(c.id) > 1
),
movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(MAX(CASE WHEN m.note IS NOT NULL THEN m.note ELSE 'No Note' END), 'Unknown') AS movie_note,
        MIN(c.kind) AS company_type
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(rr.rank, 0) AS rank,
    ar.role_count,
    md.movie_note,
    md.company_type
FROM 
    movie_details md
LEFT JOIN 
    ranked_movies rr ON md.title = rr.title AND md.production_year = rr.production_year
LEFT JOIN 
    actor_roles ar ON md.movie_id = ar.movie_id
WHERE 
    (md.movie_note IS NOT NULL OR ar.role_count IS NOT NULL)
ORDER BY 
    md.production_year DESC, md.title;
