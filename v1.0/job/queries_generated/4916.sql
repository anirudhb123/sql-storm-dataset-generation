WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title ASC) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(COALESCE(m.production_year, 0)) AS average_year
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    LEFT JOIN 
        title m ON c.movie_id = m.id
    GROUP BY 
        ak.id
), 
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mk.keyword,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, mk.keyword
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ai.actor_name,
    ai.movie_count,
    ai.average_year,
    md.movie_id,
    md.title AS movie_title,
    md.keyword,
    md.company_count
FROM 
    RankedTitles rt
JOIN 
    ActorInfo ai ON ai.movie_count > 5
LEFT JOIN 
    MovieDetails md ON rt.title = md.title
WHERE 
    rt.title_rank <= 10 
ORDER BY 
    rt.production_year DESC, 
    ai.movie_count DESC;
