WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        m.movie_id,
        COALESCE(m.Title, 'Unknown Title') AS title,
        COALESCE(cm.company_count, 0) AS company_count,
        COALESCE(cd.cast_count, 0) AS cast_count,
        COALESCE(cd.actors, 'No actors') AS actors,
        m.production_year,
        CASE 
            WHEN m.rank_year <= 3 THEN 'Top Recent'
            ELSE 'Other' 
        END AS movie_category
    FROM 
        RankedMovies m
    LEFT JOIN 
        CompanyMovieCounts cm ON m.movie_id = cm.movie_id
    LEFT JOIN 
        CastDetails cd ON m.movie_id = cd.movie_id
)
SELECT 
    d.title,
    d.production_year,
    d.company_count,
    d.cast_count,
    d.actors,
    d.movie_category
FROM 
    DetailedMovieInfo d
WHERE 
    d.movie_category = 'Top Recent'
ORDER BY 
    d.production_year DESC, d.title;
