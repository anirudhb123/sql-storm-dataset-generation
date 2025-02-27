WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(c.name, 'Unknown') AS company_name,
        c.country_code,
        r.role
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        role_type r ON mi.info_type_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, r.role, c.name, c.country_code
),
CastInfo AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT an.name) AS cast,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name an ON c.person_id = an.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.company_name,
    mi.country_code,
    ci.cast,
    ci.cast_count
FROM 
    MovieInfo mi
JOIN 
    CastInfo ci ON mi.movie_id = ci.movie_id
ORDER BY 
    mi.production_year DESC, 
    ci.cast_count DESC;
