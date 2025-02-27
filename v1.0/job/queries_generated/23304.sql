WITH MovieActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY a.person_id, a.name
),

MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.movie_id
),

TopActors AS (
    SELECT 
        ma.person_id,
        ma.name,
        ma.movie_count,
        ma.movie_titles,
        RANK() OVER (ORDER BY ma.movie_count DESC) AS rank
    FROM MovieActors ma
    WHERE ma.movie_count > 5
),

MoviesWithGenre AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT kt.kind_id) AS genre_count
    FROM aka_title mt
    LEFT JOIN kind_type kt ON mt.kind_id = kt.id
    GROUP BY mt.id
),

FinalBenchmark AS (
    SELECT 
        ta.name AS actor_name,
        ta.movie_count,
        mwk.keyword_count,
        mwk.keywords,
        mwg.genre_count,
        COALESCE(mg.name, 'Unknown') AS production_company
    FROM TopActors ta
    LEFT JOIN MoviesWithKeywords mwk ON mwk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
    LEFT JOIN MoviesWithGenre mwg ON mwg.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
    LEFT JOIN (
        SELECT 
            mc.movie_id, 
            cn.name
        FROM movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        WHERE cn.country_code IS NOT NULL
        GROUP BY mc.movie_id, cn.name
    ) mg ON mwg.movie_id = mg.movie_id
)

SELECT 
    actor_name,
    movie_count,
    keyword_count,
    keywords,
    genre_count,
    ROW_NUMBER() OVER (ORDER BY movie_count DESC, actor_name) AS row_num
FROM FinalBenchmark
WHERE keyword_count IS NOT NULL 
AND genre_count > 1
ORDER BY movie_count DESC, actor_name;


This query demonstrates a variety of SQL constructs such as CTEs, window functions, string aggregation, complex predicates, and outer joins. It benchmarks actors based on movie count, keywords associated with their movies, and genre diversity while handling NULL logic. Additionally, it ranks the actors based on their performance and presents a final list while excluding actors without keyword counts and ensuring they are associated with more than one genre.
