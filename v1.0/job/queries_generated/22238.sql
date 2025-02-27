WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
DistinctCompanyGenres AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT ct.kind, ', ') AS genres
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(dc.genres, 'No Genres') AS genres,
    CASE 
        WHEN rm.movie_rank = 1 THEN 'First Movie of Year'
        WHEN rm.movie_rank > 1 AND rm.movie_rank <= 5 THEN 'Top 5 Movies of Year'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    DistinctCompanyGenres dc ON rm.movie_id = dc.movie_id
WHERE 
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN 
        (SELECT DISTINCT ci.person_id 
         FROM cast_info ci 
         WHERE ci.movie_id = rm.movie_id)) > 5
    AND rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, 
    rm.movie_rank ASC; 
