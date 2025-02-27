WITH RecursiveMovieData AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year AS year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY year DESC) AS rank
    FROM 
        RecursiveMovieData
)
SELECT 
    title,
    year,
    actors,
    company_types,
    keywords
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    year DESC;
