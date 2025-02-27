WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title m ON ci.movie_id = m.id
    WHERE m.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        rm.actor_id,
        rm.actor_name,
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM RankedMovies rm
    LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY rm.actor_id, rm.actor_name, rm.movie_id, rm.movie_title, rm.production_year
),
RecentMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        production_year,
        keywords,
        CASE 
            WHEN production_year >= 2000 THEN '21st Century'
            WHEN production_year >= 1900 THEN '20th Century'
            ELSE 'Before 1900'
        END AS century
    FROM MoviesWithKeywords
    WHERE rn = 1
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        pi.info AS actor_info
    FROM aka_name a
    LEFT JOIN person_info pi ON a.person_id = pi.person_id
    WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
)
SELECT 
    rm.actor_id,
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    rm.keywords,
    rm.century,
    COALESCE(ai.actor_info, 'No Biography Available') AS actor_biography
FROM RecentMovies rm
LEFT JOIN ActorInfo ai ON rm.actor_id = ai.actor_id
WHERE rm.keywords IS NOT NULL
ORDER BY rm.production_year DESC, rm.actor_name;
