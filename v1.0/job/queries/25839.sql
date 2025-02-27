WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_as,
        FORMAT('%s (%d)', mt.title, mt.production_year) AS title_with_year,
        mt.kind_id,
        kt.kind AS kind
    FROM 
        aka_title mt
    JOIN 
        cast_info cc ON mt.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    LEFT JOIN 
        kind_type kt ON mt.kind_id = kt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id, kt.kind
),
FilteredRankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        cast_count,
        known_as,
        title_with_year,
        kind,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 3
)
SELECT 
    fr.movie_title,
    fr.title_with_year,
    fr.cast_count,
    fr.known_as,
    fr.kind
FROM 
    FilteredRankedMovies fr
WHERE 
    fr.rank <= 5
ORDER BY 
    fr.kind, fr.rank;
