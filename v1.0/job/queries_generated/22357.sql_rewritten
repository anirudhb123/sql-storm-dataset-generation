WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.total_cast > 2 
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.total_cast,
        COALESCE(mk.all_keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywords mk ON fm.movie_id = mk.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles
    FROM 
        cast_info ci
    WHERE 
        ci.person_role_id IS NOT NULL
    GROUP BY 
        ci.movie_id
),
FinalResults AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.total_cast,
        mwk.keywords,
        cR.distinct_roles
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        CastRoles cR ON mwk.movie_id = cR.movie_id
    WHERE 
        mwk.total_cast IS NOT NULL
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.keywords,
    COALESCE(fr.distinct_roles, 0) AS distinct_roles,
    CASE 
        WHEN fr.total_cast IS NULL THEN 'Missing Total Cast'
        WHEN fr.distinct_roles IS NULL THEN 'Roles Not Available'
        ELSE 'Data Present' 
    END AS data_status
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.total_cast DESC
LIMIT 10;