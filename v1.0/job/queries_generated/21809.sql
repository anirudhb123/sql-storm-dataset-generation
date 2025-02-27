WITH Recursive_CTE AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.note,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NOT NULL
),
Actor_Movies AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
),
Movie_Info AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id
),
Outer_Join_Movies AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        mi.movie_info,
        mi.keyword_count,
        COALESCE(ami.info, 'No Ratings') AS imdb_rating
    FROM 
        Actor_Movies am
    LEFT JOIN 
        Movie_Info mi ON am.movie_title = mi.movie_info AND mi.movie_info IS NOT NULL
    LEFT JOIN 
        (SELECT 
             movie_id, info 
         FROM 
             movie_info 
         WHERE 
             info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') 
         ) ami ON am.movie_title = ami.movie_title
)
SELECT 
    *,
    CASE 
        WHEN keyword_count > 10 THEN 'High Interest'
        WHEN keyword_count BETWEEN 5 AND 10 THEN 'Moderate Interest'
        ELSE 'Low Interest'
    END AS interest_level,
    actor_order,
    NULLIF(recent_movie_rank, 1) AS rank_null_case
FROM 
    Outer_Join_Movies
WHERE 
    production_year IS NOT NULL AND 
    actor_name IS NOT NULL
ORDER BY 
    production_year DESC, 
    actor_name, 
    movie_title;

