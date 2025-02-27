WITH RecursiveActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
),
TitleUsage AS (
    SELECT 
        t.title AS title_name,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.title
),
DistinctDirectors AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT co.name) AS director_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id 
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        m.movie_id
),
CombinedData AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(ru.actor_count, 0) AS actor_count,
        COALESCE(dd.director_count, 0) AS director_count
    FROM 
        aka_title t
    LEFT JOIN 
        TitleUsage ru ON t.title = ru.title_name
    LEFT JOIN 
        DistinctDirectors dd ON t.movie_id = dd.movie_id
),
FilteredData AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_count,
        director_count
    FROM 
        CombinedData
    WHERE 
        actor_count > 0 AND director_count > 0
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.director_count,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CASE 
        WHEN f.actor_count >= 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT STRING_AGG(name, ', ') 
     FROM aka_name 
     WHERE person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = f.title_id)
    ) AS all_actors
FROM 
    FilteredData f
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC;
