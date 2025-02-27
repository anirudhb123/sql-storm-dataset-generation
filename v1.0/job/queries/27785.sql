WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ARRAY_AGG(DISTINCT ak.name) AS known_aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        num_cast_members DESC, t.production_year DESC
    LIMIT 10
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.num_cast_members,
    COALESCE(rm.known_aliases, '{}') AS known_aliases,
    COALESCE(rm.keywords, 'No keywords') AS keywords,
    ct.kind AS company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ct.kind IS NOT NULL
ORDER BY 
    rm.num_cast_members DESC;
