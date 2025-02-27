WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM 
        aka_title m 
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieKeywords AS (
    SELECT 
        mt.movie_id, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_present
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_types
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.depth,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keywords,
    COALESCE(pr.total_actors, 0) AS actor_count,
    COALESCE(pr.roles_present, 0) AS roles_count,
    COALESCE(mi.info_types, 'No Info') AS movie_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id AND mk.keyword_rank <= 3
LEFT JOIN 
    PersonRoles pr ON mh.movie_id = pr.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.depth <= 3
ORDER BY 
    mh.movie_id, 
    mk.keyword_rank;
This SQL query accomplishes the following:
1. It recursively builds a hierarchy of movies connected via links in `aka_title`, limited to a depth of 3.
2. It collects keywords for each movie and ranks them.
3. It counts the total number of actors and roles present for each movie.
4. It aggregates information types associated with each movie into a single string.
5. The final result is presented with relevant details, ensuring that missing info is handled through `COALESCE` for better clarity in results. Results are ordered by movie ID and keyword rank.
