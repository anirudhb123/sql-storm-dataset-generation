
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        COUNT(DISTINCT a.id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.title, t.production_year, k.keyword, ct.kind
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        movie_keyword, 
        company_type, 
        actor_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title, 
    production_year, 
    movie_keyword, 
    company_type, 
    actor_count
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, actor_count DESC;
