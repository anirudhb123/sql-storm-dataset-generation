
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER(ORDER BY a.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON mc.movie_id = a.id
    JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    GROUP BY 
        a.title, a.production_year, c.name
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        keywords,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    movie_title,
    production_year,
    company_name,
    keywords,
    actor_count
FROM 
    TopMovies
ORDER BY 
    production_year DESC, actor_count DESC;
