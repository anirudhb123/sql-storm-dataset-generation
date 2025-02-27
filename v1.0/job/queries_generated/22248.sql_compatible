
WITH RECURSIVE NeighborLinks AS (
    SELECT 
        a.movie_id, 
        b.linked_movie_id, 
        b.link_type_id, 
        1 AS recursion_level
    FROM movie_link b
    JOIN aka_title a ON a.id = b.movie_id
    WHERE a.production_year > 2000
    
    UNION ALL
    
    SELECT 
        n.movie_id, 
        ml.linked_movie_id, 
        ml.link_type_id, 
        n.recursion_level + 1
    FROM movie_link ml
    JOIN NeighborLinks n ON n.linked_movie_id = ml.movie_id
    WHERE n.recursion_level < 3  
),
TitleWithCast AS (
    SELECT 
        at.title, 
        at.production_year, 
        ak.name AS actor_name, 
        ak.id AS actor_id, 
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_order,
        at.id AS title_id
    FROM aka_title at
    JOIN cast_info ci ON at.movie_id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ak.name IS NOT NULL 
        AND ak.name != '' 
        AND ak.name NOT LIKE '%(uncredited)%'
),
FilteredMovies AS (
    SELECT 
        tt.id AS title_id,
        tt.title, 
        tt.production_year,
        COUNT(tc.actor_id) AS actor_count
    FROM aka_title tt
    LEFT JOIN TitleWithCast tc ON tt.id = tc.title_id
    GROUP BY tt.id, tt.title, tt.production_year
    HAVING COUNT(tc.actor_id) > 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(nl.linked_movie_id, -1) AS linked_movie_id,
    CASE 
        WHEN fm.actor_count >= 10 THEN 'Popular Movie'
        ELSE 'Lesser Known Movie'
    END AS popularity_indicator,
    CASE 
        WHEN fm.actor_count IS NULL THEN 'No Actors'
        WHEN fm.actor_count > 20 THEN 'Star-Studded Cast'
        ELSE 'Moderate Cast'
    END AS cast_profile
FROM FilteredMovies fm
LEFT JOIN NeighborLinks nl ON fm.title_id = nl.movie_id
ORDER BY fm.production_year DESC, fm.title;
