WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM RankedMovies
    WHERE rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM TopMovies tm
    LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY tm.movie_id, tm.title, tm.production_year
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(m.keywords, 'No keywords available') AS keywords,
    ak.name AS actor_name,
    ak.imdb_index,
    ku.kind AS company_kind,
    cs.kind AS cast_type
FROM MoviesWithKeywords m
LEFT JOIN cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_type ku ON mc.company_type_id = ku.id
LEFT JOIN comp_cast_type cs ON ci.person_role_id = cs.id
WHERE m.production_year IS NOT NULL 
AND (ak.name IS NOT NULL OR ku.kind IS NULL)
ORDER BY m.production_year DESC, m.cast_count DESC;
