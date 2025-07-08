
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        0 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        mh.level + 1
    FROM aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    INNER JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mk.keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM MovieHierarchy mh
    LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS starring_count,
    ARRAY_AGG(DISTINCT an.name) AS actor_names,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
FROM TopMovies tm
LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN aka_name an ON ci.person_id = an.person_id
LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
WHERE tm.rn <= 10
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.keywords
ORDER BY tm.production_year DESC, starring_count DESC;
