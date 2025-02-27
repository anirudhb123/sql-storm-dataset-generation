WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        r.role AS cast_role,
        ak.name AS actor_name,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year, c.name, r.role, ak.name
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    company_name,
    cast_role,
    actor_name,
    keyword_count
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, keyword_count DESC;
