WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE title LIKE '%Avengers%')
    
    UNION ALL 
    
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.person_id
    WHERE 
        ah.level < 3
),
MovieDetails AS (
    SELECT 
        at.title, 
        at.production_year, 
        mci.company_id, 
        cn.name AS company_name, 
        GROUP_CONCAT(DISTINCT ak.name) AS actors
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mci ON at.id = mci.movie_id
    LEFT JOIN 
        company_name cn ON mci.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year > 2000
    GROUP BY 
        at.title, at.production_year, mci.company_id, cn.name
),
FilteredMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) as rank
    FROM 
        MovieDetails
    WHERE 
        company_name IS NOT NULL
)

SELECT 
    mv.title,
    mv.production_year,
    mv.company_name,
    COALESCE(mv.actors, 'No actors') AS actors_list,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mv.id) AS info_count,
    CASE 
        WHEN mv.production_year < 2010 THEN 'Classic'
        WHEN mv.production_year >= 2010 AND mv.production_year < 2020 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    FilteredMovies mv
WHERE 
    mv.rank <= 5
ORDER BY 
    mv.production_year DESC,
    mv.title;
