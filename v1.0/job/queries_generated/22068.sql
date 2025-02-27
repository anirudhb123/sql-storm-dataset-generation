WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROUND(AVG(CASE WHEN ci.note IS NOT NULL THEN LENGTH(ci.note) ELSE 0 END), 2) AS avg_note_length,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.id
), 
FilteredMovies AS (
    SELECT 
        rm.*,
        COALESCE((SELECT MIN(mr.production_year) FROM RankedMovies mr WHERE mr.rank_by_cast_count = 1 AND mr.production_year < rm.production_year), 0) AS prev_top_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
), 
DistinctActors AS (
    SELECT DISTINCT 
        a.id AS actor_id, 
        a.name
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        FilteredMovies fm ON fm.movie_id = ci.movie_id
    WHERE 
        a.name IS NOT NULL
), 
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
        COUNT(DISTINCT k.id) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.avg_note_length,
    da.actor_id,
    da.name AS actor_name,
    ks.movie_keywords,
    ks.total_keywords,
    CASE 
        WHEN fm.prev_top_year > 0 THEN 'Has Previous Top Movie'
        ELSE 'No Previous Top Movie'
    END AS historical_context,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = fm.movie_id AND mc.note IS NULL) AS null_notes_count,
    EXISTS (SELECT 1 FROM character_name cn WHERE cn.name_pcode_nf = 'XXXXX' LIMIT 1) AS has_obscure_character
FROM 
    FilteredMovies fm
LEFT JOIN 
    DistinctActors da ON fm.movie_id = (SELECT md.movie_id FROM cast_info ci JOIN aka_title md ON ci.movie_id = md.movie_id WHERE ci.person_id = da.actor_id LIMIT 1)
LEFT JOIN 
    KeywordStats ks ON ks.movie_id = fm.movie_id
WHERE 
    fm.cast_count > 5
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
