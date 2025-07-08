
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
), FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actors,
        companies,
        keywords,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, movie_title ASC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actors,
    companies,
    keywords
FROM 
    FilteredMovies
WHERE 
    rank <= 50
ORDER BY 
    production_year DESC, movie_title ASC;
