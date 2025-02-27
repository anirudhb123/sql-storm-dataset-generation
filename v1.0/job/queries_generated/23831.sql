WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY[t.title] AS title_path
    FROM title t
    WHERE t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.title_path || t.title
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
),
ActorDetails AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        MAX(t.production_year) AS last_year
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY ka.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
),
GenreCounts AS (
    SELECT 
        mt.movie_id,
        k.keyword AS genre,
        COUNT(mk.id) AS genre_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON mk.movie_id = mc.movie_id
    JOIN movie_title mt ON mc.movie_id = mt.id
    WHERE k.keyword IS NOT NULL
    GROUP BY mt.movie_id, k.keyword
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ad.actor_name,
    ad.total_movies,
    ad.last_year,
    gc.genre,
    gc.genre_count,
    CASE 
        WHEN gc.genre_count IS NOT NULL THEN 'Has Genre'
        ELSE 'No Genre'
    END AS genre_status
FROM MovieHierarchy mh
LEFT JOIN ActorDetails ad ON mh.movie_id = ANY(ad.actor_name)
LEFT JOIN GenreCounts gc ON mh.movie_id = gc.movie_id
ORDER BY mh.production_year DESC, ad.total_movies DESC, gc.genre_count DESC;

### Explanation of the Query

1. **CTEs (Common Table Expressions)**:
   - `MovieHierarchy`: This recursive CTE builds a hierarchy of linked movies, gathering all titles and their paths based on links between them using the `movie_link` table.
   - `ActorDetails`: This CTE aggregates actor information, counting their appearances in movies and retrieving the last year they acted, filtering to retain only those appearing in more than five movies.
   - `GenreCounts`: This aggregates the counts of genres assigned to movies.

2. **Main SELECT Statement**:
   - Combines the three CTEs, utilizing left joins to ensure all movies are included, even if they lack matching actors or genres.
   - It generates a status message (`genre_status`) based on whether a genre exists for the movie.

3. **Outer Joins**: Ensures that movies without associated actors or genres still show up in the results.

4. **CASE Statement**: Demonstrates handling NULL values for genres while providing a meaningful output.

5. **Aggregations**: Utilizes count and max functions to derive statistics on actors and genres, providing a comprehensive overview.

This query showcases the complexities and capabilities of SQL, including recursive CTEs, handling of NULLs, outer joins, and aggregations.
