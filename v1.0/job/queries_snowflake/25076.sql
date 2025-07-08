
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.id) AS cast_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        cast_count,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY production_year DESC, title ASC) AS movie_rank,
    title,
    production_year,
    actor_name,
    cast_count,
    keywords
FROM 
    TopMovies
ORDER BY 
    production_year DESC, title ASC;
