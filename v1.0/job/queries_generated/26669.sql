WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        title.title AS movie_title,
        title.production_year,
        ct.kind AS role_type
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title ON c.movie_id = title.id
    JOIN 
        role_type ct ON c.role_id = ct.id
),

keyword_movies AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),

company_movies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_summary
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    mc.movie_id,
    mc.movie_title,
    mc.production_year,
    STRING_AGG(DISTINCT mc.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT mc.role_type, ', ') AS roles,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cm.company_name || ' (' || cm.company_type || ')', ', ') AS companies,
    mis.info_summary
FROM 
    movie_cast mc
LEFT JOIN 
    keyword_movies km ON mc.movie_id = km.movie_id
LEFT JOIN 
    company_movies cm ON mc.movie_id = cm.movie_id
LEFT JOIN 
    movie_info_summary mis ON mc.movie_id = mis.movie_id
GROUP BY 
    mc.movie_id, mc.movie_title, mc.production_year
ORDER BY 
    mc.production_year DESC;
