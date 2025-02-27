WITH RoleStats AS (
    SELECT 
        ci.person_id,
        rt.role AS Role,
        COUNT(ci.movie_id) AS MovieCount,
        AVG(COALESCE(mi.note, '0'))::float AS AvgNote,
        SUM(CASE 
            WHEN mi.info IS NOT NULL THEN 1 
            ELSE 0 
        END) AS InfoCount
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        ci.person_id, rt.role
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS CastCount,
        ROUND(AVG(COALESCE(mk.keyword, '0')::numeric), 2) AS AvgKeywordCount,
        SUM(CASE WHEN co.company_id IS NULL THEN 0 ELSE 1 END) AS CompanyCount
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies co ON mt.id = co.movie_id
    WHERE 
        mt.production_year > 2000
    GROUP BY 
        mt.title, mt.production_year
),
RankedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.CastCount,
        md.AvgKeywordCount,
        md.CompanyCount,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.CastCount DESC) AS YearRank
    FROM 
        MovieDetails md
)
SELECT 
    rs.person_id,
    rs.Role,
    rs.MovieCount,
    rm.title,
    rm.production_year,
    rm.CastCount,
    rm.AvgKeywordCount,
    rm.CompanyCount,
    CASE 
        WHEN rm.CastCount > 10 AND rs.MovieCount >= 5 THEN 'Star'
        WHEN rm.CastCount <= 10 AND rs.MovieCount < 5 THEN 'Supporting'
        ELSE 'Unknown'
    END AS Classification
FROM 
    RoleStats rs
INNER JOIN 
    RankedMovies rm ON rs.person_id IN (
        SELECT c.person_id FROM cast_info c WHERE c.movie_id IN (
            SELECT mt.id FROM aka_title mt WHERE mt.production_year > 2000
        )
    )
WHERE 
    rm.YearRank <= 5
    AND rs.AvgNote IS NOT NULL
ORDER BY 
    rm.production_year DESC, rs.MovieCount DESC, rm.CastCount DESC;
