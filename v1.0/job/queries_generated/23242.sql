WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = t.id) AS keyword_count
    FROM 
        title AS t
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_note,
        MAX(ci.nr_order) AS max_order
    FROM 
        cast_info AS ci
    JOIN 
        RankedMovies AS rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        c.movie_id
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
OuterJoinResults AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_with_note,
        cd.max_order,
        mk.keywords,
        COALESCE(cd.total_cast - cd.cast_with_note, 0) AS cast_without_note
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CastDetails AS cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords AS mk ON rm.movie_id = mk.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year,
    total_cast, 
    cast_with_note, 
    keywords, 
    cast_without_note,
    CASE 
        WHEN total_cast IS NULL THEN 'No cast information'
        WHEN total_cast > 0 THEN 'Has cast'
        ELSE 'No cast'
    END AS cast_status
FROM 
    OuterJoinResults
WHERE 
    (production_year = 2022 OR production_year = 2023) 
    AND (total_cast IS NOT NULL OR total_cast = 0)
ORDER BY 
    production_year DESC, 
    rank 
LIMIT 100;
