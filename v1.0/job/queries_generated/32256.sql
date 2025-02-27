WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, 
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           ARRAY_AGG(DISTINCT t.title) AS movies
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    WHERE an.name IS NOT NULL AND at.production_year IS NOT NULL
    GROUP BY ci.person_id
), AvgMovies AS (
    SELECT AVG(movie_count) AS avg_movies
    FROM ActorHierarchy
), RankedActors AS (
    SELECT ah.person_id,
           ah.movie_count,
           ah.movies,
           RANK() OVER (ORDER BY ah.movie_count DESC) AS rank
    FROM ActorHierarchy ah
    WHERE ah.movie_count > (SELECT avg_movies FROM AvgMovies)
)
SELECT a.id AS actor_id,
       an.name AS actor_name,
       ra.movie_count,
       ra.movies,
       COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords,
       COALESCE(ci.note, 'No Note') AS role_note
FROM RankedActors ra
JOIN aka_name an ON ra.person_id = an.person_id
LEFT JOIN movie_keyword mk ON ra.movies && (SELECT ARRAY_AGG(m.id) FROM aka_title m WHERE m.title = ANY(ra.movies))
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN cast_info ci ON ra.person_id = ci.person_id AND ci.movie_id = ANY(ra.movies)
WHERE an.name NOT LIKE '%Unknown%'
GROUP BY a.id, an.name, ra.movie_count, ra.movies, ci.note
ORDER BY ra.movie_count DESC, an.name;

### Query Explanation:

1. **CTE ActorHierarchy**: This calculates the number of distinct movies for each actor, generating a list of all titles they have been involved with.

2. **CTE AvgMovies**: This calculates the average number of movies across all actors.

3. **CTE RankedActors**: Using window functions, this ranks the actors based on their movie count. It filters out actors who don't exceed the average movie count calculated.

4. **Final SELECT Statement**: This pulls together the actor details, their movie count, a concatenated list of movies, associated keywords (if any), and their role notes. It includes string aggregation for keywords and makes use of conditions to cope with potential NULLs effectively using the `COALESCE` function.

5. **JOIN and LEFT JOINs**: Several joins are used, linking actors with their names, movie keywords, and additional cast info. The left joins ensure that even if there are no associated keywords or notes, the actor details still show.

6. **Filtering and Ordering**: The result excludes actors whose names contain 'Unknown' and orders them by movie count and actor name for better clarity.
