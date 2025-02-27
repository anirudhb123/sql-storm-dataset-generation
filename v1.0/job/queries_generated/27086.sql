WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        a.kind_id AS KindID,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS YearRank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
),
TopRankedMovies AS (
    SELECT 
        RM.MovieTitle,
        RM.ProductionYear,
        RM.KindID,
        COUNT(CAST.id) AS CastCount
    FROM 
        RankedMovies RM
    JOIN 
        complete_cast CC ON RM.MovieTitle = CC.movie_id
    JOIN 
        cast_info CAST ON CC.subject_id = CAST.person_id
    WHERE 
        RM.YearRank <= 10
    GROUP BY 
        RM.MovieTitle, RM.ProductionYear, RM.KindID
),
MoviesWithKeywords AS (
    SELECT 
        T.MovieTitle,
        T.ProductionYear,
        T.CastCount,
        STRING_AGG(DISTINCT K.keyword, ', ') AS Keywords
    FROM 
        TopRankedMovies T
    JOIN 
        movie_keyword MK ON T.MovieTitle = MK.movie_id
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        T.MovieTitle, T.ProductionYear, T.CastCount
)
SELECT 
    MW.MovieTitle,
    MW.ProductionYear,
    MW.CastCount,
    MW.Keywords,
    COALESCE(CAST(ci.info, 'No info available') AS info 
    FROM 
        movie_info MI
    JOIN 
        info_type IT ON MI.info_type_id = IT.id
    LEFT JOIN 
        person_info PI ON PI.person_id = (SELECT id FROM aka_name WHERE name = (SELECT CAST.name FROM cast_info CAST WHERE id = (SELECT MIN(id) FROM cast_info)))
    WHERE 
        MI.movie_id = MW.MovieTitle
    LIMIT 1) AS CastInfo 
FROM 
    MoviesWithKeywords MW
ORDER BY 
    MW.ProductionYear DESC, MW.CastCount DESC;
