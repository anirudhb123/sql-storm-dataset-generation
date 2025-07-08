
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
RankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_names,
        keywords,
        company_count,
        RANK() OVER (ORDER BY production_year DESC, company_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_names,
    keywords,
    company_count,
    rank
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    rank;
