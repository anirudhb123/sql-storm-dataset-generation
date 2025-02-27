
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        cast_info ci
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    WHERE 
        ci.nr_order < 5
    GROUP BY 
        cc.movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 2 AND COUNT(DISTINCT mk.keyword_id) > 3
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        tc.actor_count,
        mc.companies,
        mc.company_types
    FROM 
        RankedTitles rt
    LEFT JOIN 
        TopRatedMovies tc ON rt.title_id = tc.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rt.title_id = mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.actor_count, 0) AS actor_count,
    COALESCE(m.companies, 'Unknown') AS companies,
    COALESCE(m.company_types, 'Unknown') AS company_types,
    CASE 
        WHEN COALESCE(m.actor_count, 0) > 10 THEN 'Ensemble Cast'
        WHEN COALESCE(m.actor_count, 0) BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_type
FROM 
    MoviesWithDetails m
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year ASC, m.title ASC;
