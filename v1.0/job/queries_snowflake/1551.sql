
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
    HAVING COUNT(mk.keyword_id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(pk.keyword, 'No Popular Keyword') AS popular_keyword,
        CASE 
            WHEN rm.rank_per_year <= 3 THEN 'Top 3' 
            ELSE 'Other' 
        END AS rank_category
    FROM RankedMovies rm
    LEFT JOIN PopularKeywords pk ON rm.movie_id = pk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.popular_keyword,
    md.rank_category,
    COALESCE(ci.notes, 'No Notes') AS cast_info_notes
FROM MovieDetails md
LEFT JOIN (
    SELECT 
        movie_id,
        LISTAGG(note, '; ') WITHIN GROUP (ORDER BY note) AS notes
    FROM cast_info
    GROUP BY movie_id
) ci ON md.movie_id = ci.movie_id
ORDER BY md.production_year DESC, md.cast_count DESC;
