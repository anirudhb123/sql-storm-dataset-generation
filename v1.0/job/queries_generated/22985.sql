WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        MAX(t.production_year) AS latest_movie_year
    FROM
        aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN aka_title t ON ci.movie_id = t.id
    GROUP BY
        a.id, a.name
),
FilteredActors AS (
    SELECT
        ai.actor_id,
        ai.actor_name,
        ai.movies_count,
        ai.latest_movie_year
    FROM
        ActorInfo ai
    WHERE
        ai.movies_count > 3
          AND ai.latest_movie_year BETWEEN 2000 AND 2023
),
MoviesWithKeywords AS (
    SELECT DISTINCT
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN aka_title mt ON mk.movie_id = mt.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mt.movie_id
),
FinalResult AS (
    SELECT
        fa.actor_name,
        fa.movies_count,
        fa.latest_movie_year,
        COALESCE(mkw.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN fa.latest_movie_year IS NULL THEN 'No Movies'
            WHEN fa.latest_movie_year < 2020 THEN 'Older Movies'
            ELSE 'Recent Movies'
        END AS movie_category
    FROM
        FilteredActors fa
    LEFT JOIN MoviesWithKeywords mkw ON mkw.movie_id IN (
        SELECT movie_id
        FROM cast_info
        WHERE person_id = fa.actor_id
    )
    ORDER BY
        fa.latest_movie_year DESC,
        fa.actor_name ASC
)
SELECT
    *
FROM
    FinalResult
WHERE
    movie_category <> 'No Movies'
    AND (keywords LIKE '%action%' OR keywords = 'No Keywords')
ORDER BY 
    movies_count DESC, actor_name;

