WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.id IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM title m
    JOIN MovieHierarchy h ON m.episode_of_id = h.movie_id
),
CastRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS role_rank
    FROM cast_info ci
    GROUP BY ci.person_id
),
TopActors AS (
    SELECT 
        ka.name,
        kar.movies_count
    FROM aka_name ka
    JOIN CastRoles kar ON ka.person_id = kar.person_id
    WHERE kar.role_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    na.name AS actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mk.keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS ranked_movies
FROM MovieHierarchy mh
LEFT JOIN TopActors na ON na.movies_count > 3
LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE mh.production_year IS NOT NULL
ORDER BY mh.production_year DESC, ranked_movies;

### Explanation:
- **Common Table Expressions (CTEs)**:
  - **MovieHierarchy**: Generates a recursive list of movies and their hierarchy.
  - **CastRoles**: Aggregates the movie counts for each actor from `cast_info` to find the total movies acted and ranks them.
  - **TopActors**: Filters actors that have played in more than three movies and grabs their names.
  - **MovieKeywords**: Aggregates keywords associated with each movie for additional context.

- **Final Select Statement**: Joins the CTEs to get a complete view of movies along with the names of top actors based on their command over the number of movies, and includes keywords tied to the movies. The results are ordered primarily by the production year in descending order and then ranked by the number of movies released in that year. 

- **NULL Logic**: The query uses `COALESCE` to handle cases where a movie may not have keywords associated with it. 

- **Window Functions**: Utilized to create defined rankings and grouping within the selection of movies and actors.
