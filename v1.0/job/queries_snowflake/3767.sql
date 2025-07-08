
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        mk.keywords,
        ROW_NUMBER() OVER (ORDER BY md.cast_count DESC) AS rank
    FROM MovieDetails md
    LEFT JOIN MovieKeywords mk ON md.movie_id = mk.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count,
    COALESCE(tm.keywords, 'No Keywords') AS keywords
FROM TopMovies tm
WHERE tm.rank <= 10
ORDER BY tm.cast_count DESC, tm.production_year DESC
LIMIT 10;
