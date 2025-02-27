WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
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
company_reports AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        MAX(mg.info) AS last_note
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mg ON mc.movie_id = mg.movie_id AND mg.info_type_id = (
            SELECT MIN(id) 
            FROM info_type 
            WHERE info = 'Production Note'
        )
    WHERE 
        c.country_code IS NOT NULL AND ct.kind IS NOT NULL
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.num_actors, 0) AS total_actors,
    ar.roles AS actor_roles,
    COALESCE(mk.keywords, 'None') AS related_keywords,
    COALESCE(cr.company_name, 'Independent') AS production_company,
    COALESCE(cr.company_type, 'N/A') AS company_type,
    COALESCE(cr.last_note, 'No notes available') AS production_note
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_roles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    company_reports cr ON rm.movie_id = cr.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, total_actors DESC, rm.title ASC;
