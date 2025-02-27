WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS year_rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
),
TopMoviesPerYear AS (
    SELECT 
        production_year,
        title_id,
        title
    FROM RankedMovies
    WHERE year_rank = 1
),
MovieStats AS (
    SELECT 
        tm.title_id,
        tm.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM TopMoviesPerYear tm
    LEFT JOIN cast_info c ON tm.title_id = c.movie_id
    LEFT JOIN movie_companies mc ON tm.title_id = mc.movie_id
    GROUP BY tm.title_id, tm.title
),
KeywordStats AS (
    SELECT 
        m.title_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM MovieStats m
    LEFT JOIN movie_keyword mk ON m.title_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.title_id
),
NullsAndBooleans AS (
    SELECT 
        ms.title_id,
        ms.title,
        ks.keywords_list,
        CASE 
            WHEN ms.cast_count > 0 THEN TRUE
            ELSE FALSE
        END AS has_cast,
        CASE 
            WHEN ks.keywords_list IS NULL THEN 'No Keywords' 
            ELSE 'Has Keywords' 
        END AS keyword_status
    FROM MovieStats ms
    LEFT JOIN KeywordStats ks ON ms.title_id = ks.title_id
),
FinalOutput AS (
    SELECT 
        na.name,
        ndb.title,
        nab.keywords_list,
        nab.has_cast,
        nab.keyword_status
    FROM name na
    JOIN name_pcode_cf nbc ON nbc.name_pcode_cf = na.name_pcode_cf
    LEFT JOIN NULLSANDBOOLEANS nab ON nab.title_id = nbc.imdb_id
    LEFT JOIN movie_info mi ON mi.movie_id = nab.title_id
    WHERE na.gender = 'F' AND mi.info IS NOT NULL
)
SELECT 
    title,
    COALESCE(keywords_list, 'No Keywords') AS keywords_list,
    has_cast,
    keyword_status
FROM FinalOutput
WHERE has_cast OR keyword_status = 'Has Keywords'
ORDER BY title;
