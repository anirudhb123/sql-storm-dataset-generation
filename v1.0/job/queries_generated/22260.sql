WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.average_rating DESC) AS rank_by_rating,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN (
        SELECT 
            movie_id, 
            AVG(rating) AS average_rating 
        FROM 
            movie_info 
        WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
        GROUP BY 
            movie_id
    ) m ON m.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoleCounts AS (
    SELECT 
        c.role_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(a.name) AS sample_actor_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.role_id
),
OutOfOrderMovies AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT m.id) AS out_of_order_count
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON m.id = ml.movie_id
    WHERE 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'Sequel')
    GROUP BY 
        movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_by_rating,
    rw.actor_count,
    rw.sample_actor_name,
    ooo.out_of_order_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithRoleCounts rw ON rw.role_id IN (SELECT DISTINCT role_id FROM cast_info WHERE movie_id = rm.movie_id)
LEFT JOIN 
    OutOfOrderMovies ooo ON ooo.movie_id = rm.movie_id
WHERE 
    rm.rank_by_rating <= 5 
    AND (rw.actor_count > 3 OR rw.sample_actor_name LIKE '%Smith%')
ORDER BY 
    rm.production_year DESC, rm.rank_by_rating;
