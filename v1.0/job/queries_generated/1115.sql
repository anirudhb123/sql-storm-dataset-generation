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
CompanyStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
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
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.company_name,
        cs.company_type,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    cm.title,
    COALESCE(cm.production_year, 'Unknown') AS production_year,
    COALESCE(cm.company_name, 'Independent') AS company_name,
    COALESCE(cm.keywords, 'No Keywords') AS keywords,
    COUNT(cast.id) AS cast_count,
    AVG(COALESCE(CAST(mv.info AS FLOAT), 0)) AS average_movie_rating
FROM 
    CompleteMovieInfo cm
LEFT JOIN 
    cast_info cast ON cm.movie_id = cast.movie_id
LEFT JOIN 
    movie_info mv ON cm.movie_id = mv.movie_id AND mv.info_type_id = 1 
WHERE 
    cm.production_year BETWEEN 1990 AND 2020
GROUP BY 
    cm.movie_id, cm.title, cm.production_year, cm.company_name, cm.keywords
ORDER BY 
    CM.production_year DESC, CM.title ASC;
