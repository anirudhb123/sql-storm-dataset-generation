WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
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
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
PopularMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(c.company_count, 0) AS company_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyMovieCounts c ON r.movie_id = c.movie_id
    LEFT JOIN 
        MovieKeywords mk ON r.movie_id = mk.movie_id
    WHERE 
        r.rank <= 5
)
SELECT 
    pm.title, 
    pm.production_year, 
    pm.company_count, 
    pm.keywords
FROM 
    PopularMovies pm
WHERE 
    pm.company_count > (SELECT AVG(company_count) FROM CompanyMovieCounts)
ORDER BY 
    pm.production_year DESC, pm.title;
