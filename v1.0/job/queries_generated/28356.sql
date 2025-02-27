WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aliases,
        GROUP_CONCAT(DISTINCT ck.keyword ORDER BY ck.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ck ON mk.keyword_id = ck.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        aliases,
        keywords,
        companies,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    aliases,
    keywords,
    companies
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;
