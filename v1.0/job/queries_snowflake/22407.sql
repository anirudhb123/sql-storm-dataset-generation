
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ku.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword ku ON mk.keyword_id = ku.id
    WHERE 
        t.production_year IS NOT NULL
),

MovieCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),

DirectorMovies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT m.company_id) AS number_of_companies
    FROM 
        movie_companies m
    WHERE 
        m.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        m.movie_id
),

FinalBenchmark AS (
    SELECT 
        rm.title,
        rm.production_year,
        mc.actor_name,
        mc.role_name,
        dm.number_of_companies,
        CASE 
            WHEN dm.number_of_companies IS NULL THEN 'No Company'
            ELSE CAST(dm.number_of_companies AS VARCHAR)
        END AS companies_info,
        COALESCE(rm.keyword, 'No Keyword') AS keyword_info,
        mc.total_cast,
        CASE 
            WHEN mc.total_cast > 3 THEN 'Ensemble'
            WHEN mc.total_cast IS NULL THEN 'Not Available'
            ELSE 'Solo'
        END AS cast_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        DirectorMovies dm ON dm.movie_id = rm.title_id
)

SELECT 
    title,
    production_year,
    LISTAGG(DISTINCT actor_name || ' (' || role_name || ')', ', ') WITHIN GROUP (ORDER BY actor_name) AS actors_and_roles,
    MAX(companies_info) AS companies_count,
    MAX(keyword_info) AS keywords,
    AVG(CAST(total_cast AS FLOAT)) AS average_cast_size,
    SUM(CASE WHEN cast_type = 'Ensemble' THEN 1 ELSE 0 END) AS ensemble_count,
    COUNT(DISTINCT title) AS movie_count
FROM 
    FinalBenchmark
GROUP BY 
    title,
    production_year
HAVING 
    production_year >= 1990
ORDER BY 
    production_year DESC, 
    title;
