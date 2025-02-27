WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year, 
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title ASC) AS rank_per_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        mt.kind AS movie_kind, 
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        kind_type mt ON rm.kind_id = mt.id
    LEFT JOIN 
        MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
),
FinalReport AS (
    SELECT 
        rd.title,
        rd.production_year,
        rd.movie_kind,
        rd.keyword_count,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        MovieDetails rd
    LEFT JOIN 
        cast_info ci ON rd.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        rd.movie_id, rd.title, rd.production_year, rd.movie_kind, rd.keyword_count
)
SELECT 
    fr.title, 
    fr.production_year, 
    fr.movie_kind, 
    fr.keyword_count, 
    fr.cast_names
FROM 
    FinalReport fr
WHERE 
    fr.keyword_count > 5
ORDER BY 
    fr.production_year DESC, 
    fr.title ASC;
