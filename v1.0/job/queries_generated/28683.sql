WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        actor_count DESC, t.production_year DESC
    LIMIT 10
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors,
    pt.info AS production_company_info,
    it.info AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    cn.name IS NOT NULL
AND 
    ct.kind = 'Production'
ORDER BY 
    rm.actor_count DESC;
