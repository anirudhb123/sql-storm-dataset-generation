
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(cd.company_name, 'No Company') AS company_name,
        COALESCE(cd.company_count, 0) AS company_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.title_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
    WHERE 
        rm.rank_by_cast_count <= 5 
)
SELECT 
    *,
    CASE 
        WHEN production_year IS NULL THEN 'Unknown Year'
        ELSE 'Year: ' || production_year
    END AS year_description,
    (SELECT AVG(cast_count) FROM RankedMovies) AS avg_cast_per_movie,
    (SELECT COUNT(DISTINCT title_id) FROM CompleteMovieInfo WHERE company_count > 0) AS movies_with_companies,
    (SELECT COUNT(DISTINCT title_id) FROM CompleteMovieInfo WHERE keywords LIKE '%Action%') AS action_movies_count,
    CASE 
        WHEN company_count IS NULL OR company_count = 0 THEN 'No Associated Companies'
        ELSE 'Has Associated Companies'
    END AS company_status
FROM 
    CompleteMovieInfo
WHERE 
    keywords IS NOT NULL
ORDER BY 
    production_year DESC, cast_count DESC;
