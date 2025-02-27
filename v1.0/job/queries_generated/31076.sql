WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000  -- Base case: Movies from the year 2000 onward

    UNION ALL 

    SELECT 
        l.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM movie_link l
    JOIN aka_title mt ON l.linked_movie_id = mt.id
    JOIN MovieHierarchy mh ON l.movie_id = mh.movie_id
    WHERE mh.level < 3  -- Limit to 3 levels deep for the recursive join
), 

AnnotatedCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN comp_cast_type ct ON c.person_role_id = ct.id
),

MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS average_rating
    FROM aka_title m
    LEFT JOIN ratings r ON m.id = r.movie_id  -- Assuming a ratings table exists
    GROUP BY m.id
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mr.average_rating, 0) AS average_rating,
        json_agg(json_build_object('actor_name', ac.actor_name, 'role', ac.role)) AS actors
    FROM MovieHierarchy mh
    LEFT JOIN MovieRatings mr ON mh.movie_id = mr.movie_id
    LEFT JOIN AnnotatedCast ac ON mh.movie_id = ac.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
)

SELECT 
    fm.title,
    fm.production_year,
    CASE 
        WHEN fm.average_rating IS NULL THEN 'No Ratings Available'
        WHEN fm.average_rating > 4 THEN 'High Rating'
        WHEN fm.average_rating BETWEEN 2 AND 4 THEN 'Moderate Rating'
        ELSE 'Low Rating'
    END AS rating_category,
    fm.actors
FROM FilteredMovies fm
WHERE fm.production_year = (SELECT MAX(fm2.production_year) FROM FilteredMovies fm2)
ORDER BY fm.production_year DESC;
