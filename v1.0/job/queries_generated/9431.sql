WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%award%'
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    ak.name AS actor_name,
    r.role AS role
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.company_count DESC, ak.name;
