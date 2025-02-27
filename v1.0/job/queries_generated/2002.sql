WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
),
FullMovieInfo AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        COALESCE(mk.keywords, 'No Keywords') AS keywords, 
        COALESCE(cm.company_name, 'Independent') AS company_name, 
        COALESCE(cm.company_type, 'N/A') AS company_type,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        MovieKeywords AS mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyMovies AS cm ON rm.movie_id = cm.movie_id
    LEFT JOIN 
        cast_info AS ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mk.keywords, cm.company_name, cm.company_type
)
SELECT 
    f.movie_id, 
    f.title, 
    f.production_year, 
    f.keywords, 
    f.company_name, 
    f.company_type, 
    f.cast_count,
    CASE 
        WHEN f.cast_count > 5 THEN 'Ensemble Cast' 
        WHEN f.cast_count BETWEEN 1 AND 5 THEN 'Limited Cast' 
        ELSE 'No Cast' 
    END AS cast_category
FROM 
    FullMovieInfo AS f
WHERE 
    f.production_year BETWEEN 2000 AND 2023
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
