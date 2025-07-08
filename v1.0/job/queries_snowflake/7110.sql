
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.kind AS company_type, 
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        COUNT(DISTINCT km.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    GROUP BY 
        t.title, t.production_year, c.kind
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        company_type, 
        actors, 
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    title, 
    production_year, 
    company_type, 
    actors, 
    keyword_count
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
