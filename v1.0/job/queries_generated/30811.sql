WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    WHERE 
        ak.production_year >= 2000
),
RankedCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(STRING_AGG(rc.actor_name, ', '), 'No Cast') AS actors,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mh.level = 0 THEN 'Original' 
        ELSE 'Linked'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedCast rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    KeywordCount kc ON mh.movie_id = kc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, mh.title;

In this query:
- A recursive CTE `MovieHierarchy` is used to fetch movies produced from the year 2000 onwards and any linked movies.
- Another CTE `RankedCast` ranks actors by their order in the cast list for each movie.
- `KeywordCount` is a CTE that counts the number of keywords associated with each movie.
- The main query selects movie details and aggregates actor names and keyword counts, handling cases where there may be no associated actors or keywords using `COALESCE`.
- It uses a `CASE` expression to differentiate between original and linked movies based on the recursion level.
- The results are ordered by production year and title.
