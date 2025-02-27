WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL
      
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 
ActorMovies AS (
    SELECT ka.name AS actor_name, COUNT(DISTINCT ci.movie_id) AS total_movies,
           STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
    WHERE ka.name IS NOT NULL
    GROUP BY ka.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
), 
MovieWithKeywords AS (
    SELECT mt.title, COUNT(mk.keyword_id) AS keyword_count
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.title
    HAVING COUNT(mk.keyword_id) > 0
), 
RankedMovies AS (
    SELECT mt.title, 
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.title
)

SELECT 
    am.actor_name, 
    mh.level, 
    mh.title AS movie_title, 
    mh.production_year, 
    rw.rank, 
    mwk.keyword_count,
    (CASE 
        WHEN mwk.keyword_count IS NULL THEN 'No Keywords' 
        ELSE 'Has Keywords' 
    END) AS keyword_status
FROM ActorMovies am
JOIN MovieHierarchy mh ON am.total_movies > 0
LEFT JOIN MovieWithKeywords mwk ON mh.title = mwk.title
LEFT JOIN RankedMovies rw ON mh.title = rw.title
WHERE mh.production_year BETWEEN 2000 AND 2023
ORDER BY am.total_movies DESC, mh.level, mh.title;
