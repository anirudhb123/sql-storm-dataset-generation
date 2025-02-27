WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, 0) AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

ActorMovieCount AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),

TopActors AS (
    SELECT 
        a.id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCount amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > (
            SELECT AVG(movie_count)
            FROM ActorMovieCount
        )
),

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    ta.name AS Actor_Name,
    COALESCE(mk.keywords, 'No keywords') AS Keywords,
    mh.level AS Hierarchy_Level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors ta ON EXISTS (
        SELECT 1 
        FROM cast_info c 
        WHERE c.movie_id = mh.movie_id AND c.person_id = ta.id
    )
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    (mh.production_year IS NOT NULL AND mh.production_year < 2023)
ORDER BY 
    mh.production_year DESC, 
    mh.title, 
    ta.name;
