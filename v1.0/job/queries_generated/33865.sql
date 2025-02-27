WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE mt.kind_id = (
        SELECT id FROM kind_type WHERE kind = 'movie'
    )
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE at.kind_id = (
        SELECT id FROM kind_type WHERE kind = 'movie'
    )
),
ActorCount AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
TopMovieDetails AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ac.actor_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ac.actor_count DESC) AS rn
    FROM MovieHierarchy mh
    JOIN ActorCount ac ON mh.movie_id = ac.movie_id
)

SELECT
    TMD.title,
    TMD.production_year,
    TMD.actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM TopMovieDetails TMD
JOIN cast_info ci ON TMD.movie_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
WHERE 
    TMD.actor_count > 5 
    AND TMD.production_year >= 2000
GROUP BY 
    TMD.title, 
    TMD.production_year, 
    TMD.actor_count
ORDER BY
    TMD.production_year DESC, 
    TMD.actor_count DESC;

### Explanation:
1. **Recursive CTE (`MovieHierarchy`)**: This builds a hierarchy of movies from `aka_title`, allowing retrieval of linked movies based on `movie_link`.
2. **Aggregate Function (`ActorCount`)**: This computes the count of distinct actors for each movie.
3. **Window Function**: It ranks movies based on actor count for each production year.
4. **Final Selection**: The main query selects titles with more than 5 actors produced after 2000, aggregating actor names into a single string.
5. **String Aggregation**: Utilizes `STRING_AGG` to concatenate actors’ names.
6. **Complex Filtering**: Enforces multiple predicates for filtering results based on actor count and production year.
