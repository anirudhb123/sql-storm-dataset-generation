
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.cast_count,
    cd.cast_names,
    ks.keyword_count,
    CASE 
        WHEN ks.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM RankedMovies rm
LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE rm.rank_year <= 10
GROUP BY rm.title, rm.production_year, cd.cast_count, cd.cast_names, ks.keyword_count
ORDER BY rm.production_year DESC, cd.cast_count DESC NULLS LAST;
