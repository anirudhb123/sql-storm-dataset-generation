
WITH RECURSIVE ActorMovies AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ct.movie_id,
        ct.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY ct.nr_order) AS role_sequence
    FROM aka_name ak
    JOIN cast_info ct ON ak.person_id = ct.person_id
    WHERE ak.name IS NOT NULL
      AND ak.name <> ''
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),
HighRatingMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        a.actor_id,
        a.actor_name,
        COALESCE(mi.info, 'No Rating') AS movie_rating,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'rating'
    )
    LEFT JOIN ActorMovies a ON m.id = a.movie_id
    LEFT JOIN MovieKeywords mk ON m.id = mk.movie_id
    WHERE m.production_year >= 2000
      AND (mi.info IS NULL OR CAST(mi.info AS FLOAT) > 7.0)   
),
FilteredActors AS (
    SELECT 
        actor_id, 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM HighRatingMovies
    GROUP BY actor_id, actor_name
    HAVING COUNT(DISTINCT movie_id) > 5  
),
FinalResults AS (
    SELECT 
        ha.actor_id,
        ha.actor_name,
        ha.movie_count,
        COUNT(DISTINCT hm.movie_id) AS unique_movies_count,
        STRING_AGG(DISTINCT hm.title, ', ') AS movies_list
    FROM FilteredActors ha
    LEFT JOIN HighRatingMovies hm ON ha.actor_id = hm.actor_id
    GROUP BY ha.actor_id, ha.actor_name, ha.movie_count
)
SELECT 
    *,
    CASE 
        WHEN unique_movies_count > 10 THEN 'Superstar'
        WHEN unique_movies_count BETWEEN 6 AND 10 THEN 'Established Actor'
        ELSE 'Emerging Talent'
    END AS talent_status
FROM FinalResults
ORDER BY unique_movies_count DESC
LIMIT 20;
