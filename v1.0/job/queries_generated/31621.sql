WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
ActorRankings AS (
    SELECT 
        ci.person_id,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        ci.person_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(a.movie_count, 0) AS actor_participation,
        RANK() OVER (ORDER BY mh.production_year DESC, actor_participation DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRankings a ON mh.movie_id = a.sn
    WHERE 
        mh.level <= 2
)

SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    COALESCE(a.name, 'Unknown Actor') AS Actor_Name,
    CASE 
        WHEN tm.actor_participation > 0 THEN 'Participated' 
        ELSE 'No Participation'
    END AS Participation_Status
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.actor_participation DESC;
