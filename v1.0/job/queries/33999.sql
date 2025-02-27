WITH RECURSIVE MovieHierarchy AS (
    SELECT id AS movie_id, title, production_year, episode_of_id, season_nr, episode_nr
    FROM aka_title
    WHERE production_year >= 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, m.episode_of_id, m.season_nr, m.episode_nr
    FROM aka_title m
    INNER JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG( DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
TitleMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(kd.keywords, 'No keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title t
    LEFT JOIN CastDetails cd ON t.id = cd.movie_id
    LEFT JOIN KeywordDetails kd ON t.id = kd.movie_id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year, cd.total_cast, kd.keywords
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.keywords,
    CASE 
        WHEN tm.total_cast > 15 THEN 'Large Cast' 
        WHEN tm.total_cast BETWEEN 8 AND 15 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size,
    COUNT(link.linked_movie_id) AS related_movies
FROM TitleMovieInfo tm
LEFT JOIN movie_link link ON tm.movie_id = link.movie_id
WHERE tm.production_year = (SELECT MAX(production_year) FROM aka_title) 
OR tm.production_year IS NULL
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.total_cast, tm.keywords
ORDER BY tm.production_year DESC, tm.total_cast DESC;
