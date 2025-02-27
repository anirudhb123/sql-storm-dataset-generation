WITH MovieRatings AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title,
        AVG(mr.rating) AS average_rating
    FROM 
        aka_title t
    LEFT JOIN 
        movie_link ml ON t.id = ml.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_info_idx mii ON t.id = mii.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        person_info pi ON mk.keyword_id = pi.id
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_ratings) mr ON t.id = mr.movie_id
    GROUP BY 
        t.id, t.title
), RecentMovies AS (
    SELECT 
        mt.movie_id, 
        mt.movie_title, 
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY mt.average_rating DESC) AS rank
    FROM 
        MovieRatings mt
    WHERE 
        mt.average_rating > 7.0
), CastDetails AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name
)
SELECT 
    rm.movie_title,
    rm.average_rating,
    cd.actor_name,
    cd.roles,
    COALESCE(p.note, 'No additional info') AS additional_info
FROM 
    RecentMovies rm
JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    person_info p ON cd.actor_name = p.info AND p.person_id IN (SELECT person_id FROM aka_name)
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.average_rating DESC, cd.actor_name;
