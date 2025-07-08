
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.total_cast,
        COALESCE(mc.company_count, 0) AS company_count,
        mk.keywords,
        r.rank_by_cast
    FROM 
        RankedMovies r
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mc ON mc.movie_id = r.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = r.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.total_cast,
    mwc.company_count,
    mwc.keywords,
    CASE 
        WHEN mwc.total_cast > 10 THEN 'Ensemble Cast'
        WHEN mwc.total_cast BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_size_category
FROM 
    MoviesWithCompanies mwc
WHERE 
    mwc.rank_by_cast = 1 
    AND mwc.production_year IS NOT NULL
    AND mwc.company_count > 0
ORDER BY 
    mwc.production_year DESC, 
    mwc.total_cast DESC
LIMIT 10;
