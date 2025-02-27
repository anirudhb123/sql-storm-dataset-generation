WITH Recursive_Actor_Title AS (
    SELECT 
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.id ORDER BY kt.production_year DESC) AS title_rank
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN aka_title kt ON ci.movie_id = kt.movie_id
    WHERE kt.production_year IS NOT NULL
),
Title_Stats AS (
    SELECT
        actor_name,
        COUNT(movie_title) AS total_movies,
        MAX(production_year) AS latest_movie_year,
        MIN(production_year) AS earliest_movie_year,
        AVG(production_year) AS average_movie_year,
        COUNT(DISTINCT SUBSTRING(actor_name FROM '([^ ]+)')) AS distinct_first_names
    FROM Recursive_Actor_Title
    GROUP BY actor_name
),
Keywords_Aggr AS (
    SELECT 
        kt.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
    FROM aka_title kt
    LEFT JOIN movie_keyword mk ON kt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY kt.id
),
Detailed_Info AS (
    SELECT 
        ts.actor_name,
        ts.total_movies,
        ts.latest_movie_year,
        ts.earliest_movie_year,
        ts.average_movie_year,
        ts.distinct_first_names,
        ka.name AS company_name,
        ci.note AS cast_note,
        ka.md5sum AS actor_md5,
        COALESCE(ka.imdb_index, 'N/A') AS imdb_index
    FROM Title_Stats ts
    LEFT JOIN cast_info ci ON ci.nr_order = 1
    LEFT JOIN aka_name ka ON ci.person_id = ka.person_id
    WHERE NOT (ts.total_movies = 0 AND ts.actor_name IS NULL)
),
Final_Report AS (
    SELECT 
        di.actor_name,
        di.total_movies,
        di.latest_movie_year,
        di.earliest_movie_year,
        di.average_movie_year,
        di.distinct_first_names,
        CASE 
            WHEN di.latest_movie_year IS NULL THEN 'No Movies'
            WHEN di.latest_movie_year = di.earliest_movie_year THEN 'Only One Movie' 
            ELSE 'Multiple Movies' 
        END AS movie_status,
        COALESCE(ka.name, 'Unknown Company') AS company,
        (SELECT COUNT(*) FROM movie_info WHERE info_type_id = 1) AS total_info_entries,
        (SELECT COUNT(DISTINCT keyword) FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id) AS total_distinct_keywords
    FROM Detailed_Info di
    LEFT JOIN movie_companies mc ON mc.movie_id = (SELECT movie_id FROM movie_info mi WHERE mi.info LIKE '%award%')
    LEFT JOIN company_name ka ON mc.company_id = ka.id
)

SELECT 
    *, 
    (total_movies * (1.0 / NULLIF(average_movie_year, 0))) AS movies_per_year,
    CASE WHEN latest_movie_year IS NOT NULL THEN EXTRACT(YEAR FROM CURRENT_DATE) - latest_movie_year ELSE NULL END AS years_since_latest_movie
FROM Final_Report
WHERE total_movies > 2
   OR (years_since_latest_movie IS NULL AND total_info_entries > 10)
ORDER BY years_since_latest_movie DESC NULLS LAST, total_movies DESC
LIMIT 50;
