
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),

actor_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_title,
        COUNT(c.id) AS total_roles
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),

company_details AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS co ON mc.company_id = co.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        co.country_code IS NOT NULL
),

keyword_movies AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ar.role_title, 'No Role') AS role_title,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    COALESCE(km.keywords, 'No Keywords') AS keywords,
    ar.total_roles
FROM 
    ranked_movies AS rm
LEFT JOIN 
    actor_roles AS ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    company_details AS cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    keyword_movies AS km ON rm.movie_id = km.movie_id
WHERE 
    rm.rn <= 5 OR (ar.total_roles IS NOT NULL AND ar.total_roles > 2)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
