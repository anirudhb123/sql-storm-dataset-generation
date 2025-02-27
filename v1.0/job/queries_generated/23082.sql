WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.imdb_index,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.imdb_index,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
ActorDetails AS (
    SELECT 
        ak.person_id,
        ak.name,
        ct.kind AS role_name,
        COUNT(DISTINCT ci.movie_id) AS films_count,
        STRING_AGG(DISTINCT mt.title, ', ') AS films_titles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL AND 
        ak.name != ''
    GROUP BY 
        ak.person_id, ak.name, ct.kind
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END), 0) AS total_info_length,
        GROUP_CONCAT(DISTINCT kw.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title m 
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
)
SELECT 
    mh.title,
    mh.production_year,
    ad.name AS actor_name,
    ad.role_name,
    ad.films_count,
    mi.total_info_length,
    mi.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorDetails ad ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = mh.movie_id AND ci.person_id = ad.person_id
    )
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    (mh.production_year IS NOT NULL AND mh.production_year <= 2023)
    OR (mi.total_info_length > 100 AND mi.keywords IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    ad.films_count DESC;

### Explanation of the Query

1. **CTEs (Common Table Expressions)**:
   - **MovieHierarchy**: Retrieves all movies produced from the year 2000 onwards and organizes them hierarchically if they are parts of a series.
   - **ActorDetails**: Gets actor names and their roles, along with the count of films they have appeared in and concatenated titles of these films.
   - **MovieInfo**: Collects movie information including the total info length and keywords related to each movie.

2. **Main Query**:  
   The main select statement combines data from the aforementioned CTEs using outer joins. It retrieves necessary fields along with the filtering of movies based on their production year or related information length and keywords.

3. **Correlated Subquery:** 
   The query uses a correlated subquery within the `EXISTS` clause to confirm the involvement of actors in the specific movies listed in the MovieHierarchy.

4. **Complicated Filtering Logic**:
   The WHERE clause filters movies based either on their production year or based on the total information length and non-null keywords.

5. **Ordering**: 
   The results are ordered by production year descending and then by the count of films the actor has appeared in.

This query is designed for performance benchmarking, showcasing advanced SQL features, and efficiently derives insights from the complex schema of a movie database.
