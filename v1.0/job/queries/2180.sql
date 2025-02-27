WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS directors
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    WHERE 
        rt.role = 'Director'
    GROUP BY 
        ci.movie_id
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
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        di.directors,
        mk.keywords,
        COALESCE(mn.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorInfo di ON rm.movie_id = di.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mn ON rm.movie_id = mn.movie_id AND mn.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
    WHERE 
        di.directors IS NOT NULL OR mk.keywords IS NOT NULL
)
SELECT 
    movie_id,
    title,
    production_year,
    directors,
    keywords,
    additional_info
FROM 
    CompleteMovieInfo
WHERE 
    NOT (production_year < 1990 OR title IS NULL)
ORDER BY 
    production_year DESC, title;
