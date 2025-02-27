WITH RankedActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(ci.movie_id) DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        ra.actor_name,
        md.keyword_count,
        md.company_count,
        ROW_NUMBER() OVER (ORDER BY md.company_count DESC, md.keyword_count DESC) AS movie_rank
    FROM 
        MovieDetails md
    JOIN 
        RankedActors ra ON md.movie_title IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id IN (SELECT person_id FROM aka_name ak WHERE ak.name = ra.actor_name))
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    keyword_count,
    company_count
FROM 
    TopMovies
WHERE 
    movie_rank <= 10
ORDER BY 
    production_year DESC, movie_title;
