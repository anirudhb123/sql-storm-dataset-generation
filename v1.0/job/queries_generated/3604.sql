WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM RankedMovies rm
    LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY rm.movie_id, rm.title, rm.production_year, rm.cast_count
),
FilteredMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.cast_count,
        mwk.keywords,
        CASE 
            WHEN mwk.production_year >= 2000 THEN 'Modern'
            WHEN mwk.production_year < 2000 AND mwk.production_year >= 1980 THEN 'Classic'
            ELSE 'Old'
        END AS era
    FROM MoviesWithKeywords mwk
    WHERE mwk.cast_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.keywords,
    f.era,
    COALESCE(mi.info, 'No additional info') AS info
FROM FilteredMovies f
LEFT JOIN movie_info mi ON f.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
WHERE f.rank <= 10
ORDER BY f.cast_count DESC, f.production_year DESC;
