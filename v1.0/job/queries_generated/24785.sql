WITH Recursive_Actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_sequence
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL 
        AND a.name != ''
),
Movies_With_Keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
),
Filtered_Movies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.keywords,
        COALESCE(info.info, 'No additional info') AS additional_info
    FROM 
        Movies_With_Keywords mwk
    LEFT JOIN 
        movie_info info ON mwk.movie_id = info.movie_id AND info.note IS NULL
),
Counted_Actors AS (
    SELECT 
        rw.actor_id,
        rw.actor_name,
        rw.movie_id,
        rw.role_sequence,
        COUNT(*) OVER (PARTITION BY rw.actor_id) AS total_movies
    FROM 
        Recursive_Actors rw
)
SELECT 
    f.title,
    f.keywords,
    f.additional_info,
    ca.actor_name,
    ca.role_sequence,
    ca.total_movies,
    CASE 
        WHEN ca.total_movies > 5 THEN 'Veteran'
        WHEN ca.total_movies BETWEEN 3 AND 5 THEN 'Intermediate'
        ELSE 'Newcomer'
    END AS actor_experience
FROM 
    Filtered_Movies f
JOIN 
    Counted_Actors ca ON f.movie_id = ca.movie_id
WHERE 
    f.keywords LIKE '%action%' 
    AND f.additional_info NOT LIKE '%demo%'
ORDER BY 
    f.title, 
    ca.role_sequence DESC;
