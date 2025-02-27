WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        t.season_nr
    FROM title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        t.season_nr
    FROM title t
    INNER JOIN TitleHierarchy th ON t.episode_of_id = th.title_id
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        ak.name, 
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT title.title, ', ') AS titles 
    FROM aka_name ak
    INNER JOIN cast_info ci ON ak.person_id = ci.person_id
    INNER JOIN title ON ci.movie_id = title.id
    GROUP BY a.id, ak.name
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    GROUP BY m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.actor_count,
        rm.production_year
    FROM RankedMovies rm
    WHERE rm.rank <= 5
)
SELECT 
    th.title,
    th.production_year,
    ai.name AS actor_name,
    ai.movie_count AS total_movies_with_actor,
    STRING_AGG(DISTINCT fm.title, ', ') AS featured_movies
FROM TitleHierarchy th
LEFT JOIN ActorInfo ai ON th.title = ANY(ai.titles)
LEFT JOIN FilteredMovies fm ON th.id = fm.movie_id
GROUP BY th.title, th.production_year, ai.name, ai.movie_count
ORDER BY th.production_year DESC, total_movies_with_actor DESC;
