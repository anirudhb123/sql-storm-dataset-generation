WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mc.company_id,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rn
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE mt.production_year IS NOT NULL
    AND mt.production_year > 1980
),
CastRank AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
GenreKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
NullChecks AS (
    SELECT
        mt.title,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM RankedMovies mt
    LEFT JOIN GenreKeywords mk ON mt.movie_id = mk.movie_id
    LEFT JOIN CastRank ci ON mt.movie_id = ci.movie_id
    GROUP BY mt.title, mk.keywords
),
TitleInfo AS (
    SELECT
        title,
        keywords,
        actor_count,
        CASE 
            WHEN actor_count IS NULL THEN 'No Actors Listed'
            WHEN actor_count > 10 THEN 'Super Cast'
            ELSE 'Regular Cast'
        END AS cast_evaluation
    FROM NullChecks
)
SELECT 
    title,
    keywords,
    actor_count,
    cast_evaluation
FROM TitleInfo
WHERE 
    actor_count > 0
ORDER BY
    CASE cast_evaluation
        WHEN 'Super Cast' THEN 1
        WHEN 'Regular Cast' THEN 2
        ELSE 3
    END,
    title ASC
LIMIT 100 OFFSET 0;

-- Additional outlier selection with right join and NULL logic
SELECT
    t.title,
    n.name AS director_name,
    CASE 
        WHEN n.name IS NULL THEN 'Director Unknown'
        ELSE n.name 
    END AS checked_director_name
FROM title t
RIGHT JOIN company_name n ON t.imdb_id = n.imdb_id
WHERE 
    (n.country_code IS NULL OR n.country_code = 'US')
ORDER BY 
    t.title DESC
FETCH FIRST 50 ROWS ONLY;
