
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
RecentTitles AS (
    SELECT 
        title_id, 
        title, 
        production_year,
        keyword
    FROM RankedMovies
    WHERE rn <= 3
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(cc.id) AS cast_count,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        COALESCE(mci.note, 'N/A') AS movie_note
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_info mci ON t.id = mci.movie_id AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'Notes')
    GROUP BY t.id, t.title, mci.note
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    md.cast_count,
    md.actors,
    md.movie_note
FROM RecentTitles r
LEFT JOIN MovieDetails md ON r.title_id = md.movie_id
WHERE r.production_year IS NOT NULL
ORDER BY r.production_year DESC, r.title_id ASC
LIMIT 10;
