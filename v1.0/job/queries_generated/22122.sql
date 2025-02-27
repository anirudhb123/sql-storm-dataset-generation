WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.id) OVER (PARTITION BY m.id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
),

CrewDetails AS (
    SELECT 
        ci.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS crew_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        ci.movie_id, c.name, ct.kind
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

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        mk.keywords,
        cd.company_name,
        cd.company_type,
        cd.crew_count,
        CASE 
            WHEN rm.total_cast > 10 THEN 'Large Cast'
            WHEN rm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size_category
    FROM 
        RankedMovies rm
    JOIN 
        CrewDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.year_rank <= 3
    ORDER BY 
        rm.production_year DESC, rm.title
)

SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.company_name,
    tm.company_type,
    tm.crew_count,
    tm.cast_size_category,
    CASE 
        WHEN tm.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Year Known'
    END AS year_status
FROM 
    TopMovies tm
WHERE 
    (tm.cast_size_category = 'Large Cast' AND tm.crew_count > 5)
    OR
    (tm.cast_size_category = 'Small Cast' AND tm.production_year = (
        SELECT 
            MAX(production_year) 
        FROM 
            aka_title 
        WHERE 
            imdb_index IS NOT NULL
    ))
ORDER BY 
    tm.production_year DESC, tm.cast_size_category, tm.title;
