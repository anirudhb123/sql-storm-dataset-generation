WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        comp.name AS company_name,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        RankedTitles rt
    JOIN 
        movie_companies mc ON mc.movie_id = rt.id
    JOIN 
        company_name comp ON comp.id = mc.company_id
    JOIN 
        movie_keyword mk ON mk.movie_id = rt.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info c ON c.movie_id = rt.id
    GROUP BY 
        title.title, comp.name
),
FinalBenchmark AS (
    SELECT 
        md.movie_title,
        md.company_name,
        md.keywords,
        md.actor_count,
        COUNT(DISTINCT md.movie_title) OVER () AS total_movies,
        COUNT(DISTINCT md.company_name) OVER () AS total_companies
    FROM 
        MovieDetails md
)
SELECT 
    f.movie_title,
    f.company_name,
    f.keywords,
    f.actor_count,
    f.total_movies,
    f.total_companies,
    (f.actor_count * 1.0 / NULLIF(f.total_movies, 0)) AS avg_actors_per_movie
FROM 
    FinalBenchmark f
ORDER BY 
    f.actor_count DESC
LIMIT 10;
