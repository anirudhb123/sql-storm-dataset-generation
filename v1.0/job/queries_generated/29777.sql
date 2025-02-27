WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mk.keywords,
        mc.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)
SELECT 
    cmd.title AS movie_title,
    cmd.production_year,
    cmd.keywords,
    cmd.company_names,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    MAX(CASE WHEN ci.role_id = 1 THEN 'Lead' ELSE 'Supporting' END) AS lead_or_supporting
FROM 
    CompleteMovieDetails cmd
LEFT JOIN 
    cast_info ci ON cmd.movie_id = ci.movie_id
WHERE 
    cmd.production_year > 2000
GROUP BY 
    cmd.movie_id, cmd.title, cmd.production_year, cmd.keywords, cmd.company_names
ORDER BY 
    cmd.production_year DESC, cmd.title ASC;
