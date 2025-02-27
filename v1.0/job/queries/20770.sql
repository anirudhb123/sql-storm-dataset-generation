WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rank_years
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND
        t.production_year >= 2000
),
ActorYearCount AS (
    SELECT 
        actor_name,
        COUNT(*) AS title_count,
        MAX(production_year) AS last_year
    FROM 
        RankedTitles
    WHERE 
        rank_years <= 3
    GROUP BY 
        actor_name
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
),
ActorCompleteInfo AS (
    SELECT 
        ay.actor_name,
        ay.title_count,
        mk.keywords,
        ay.last_year
    FROM 
        ActorYearCount ay
    LEFT JOIN 
        MoviesWithKeywords mk ON ay.actor_name = mk.title
)
SELECT 
    ac.actor_name,
    COALESCE(ac.title_count, 0) AS title_count,
    ac.keywords,
    CASE 
        WHEN ac.last_year IS NULL THEN 'No movies after 2000'
        WHEN ac.last_year > 2010 THEN 'Active in the last decade'
        ELSE 'Inactive since the last decade'
    END AS activity_status
FROM 
    ActorCompleteInfo ac
JOIN 
    aka_name an ON ac.actor_name = an.name
WHERE 
    (ac.title_count IS NOT NULL OR ac.keywords IS NOT NULL)
ORDER BY 
    ac.title_count DESC, 
    ac.actor_name ASC
LIMIT 50;
