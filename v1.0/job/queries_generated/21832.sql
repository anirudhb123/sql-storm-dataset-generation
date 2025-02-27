WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actors_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_actors
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    WHERE 
        title.production_year IS NOT NULL
    GROUP BY 
        title.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_actors <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT CONCAT(mi.info_type_id, ': ', mi.info), '; ') AS info
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS companies_count,
        ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalResult AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mi.info, 'No info available') AS additional_info,
        COALESCE(mc.companies_count, 0) AS companies_count,
        COALESCE(mc.company_names, ARRAY[]::text[]) AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieInfo mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        MovieCompanies mc ON tm.movie_id = mc.movie_id
)
SELECT 
    *,
    CASE 
        WHEN companies_count > 5 THEN 'High' 
        WHEN companies_count BETWEEN 3 AND 5 THEN 'Medium' 
        ELSE 'Low' 
    END AS company_involvement,
    CASE 
        WHEN production_year = (SELECT MAX(production_year) FROM title) THEN 'Latest Release'
        ELSE 'Not Latest'
    END AS release_status,
    NULLIF(NULLIF(title, ''), 'No Title') AS display_title
FROM 
    FinalResult
ORDER BY 
    rank_actors, production_year DESC;
