WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM aka_title at
    JOIN cast_info ci ON at.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY at.id, at.title, at.production_year, ak.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        actor_count
    FROM RankedMovies
    WHERE actor_rank <= 3
),
MovieKeywords AS (
    SELECT 
        tm.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM TopMovies tm
    JOIN movie_keyword mk ON tm.title = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY tm.title
),
MovieInfoDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        mk.keywords,
        GROUP_CONCAT(DISTINCT pi.info) AS person_info
    FROM TopMovies tm
    LEFT JOIN person_info pi ON pi.person_id IN (
        SELECT ci.person_id 
        FROM cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
        WHERE ak.name = tm.actor_name
    )
    LEFT JOIN MovieKeywords mk ON mk.title = tm.title
    GROUP BY tm.title, tm.production_year, mk.keywords
)
SELECT 
    title,
    production_year,
    CONCAT('Keywords: ', keywords) AS keyword_summary,
    person_info
FROM MovieInfoDetails
ORDER BY production_year DESC, title;
