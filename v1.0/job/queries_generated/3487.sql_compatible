
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CAST(mi.info AS NUMERIC)) AS average_rating
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        t.title, t.production_year
), 
HighActorCount AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        average_rating,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rn
    FROM 
        RankedMovies
    WHERE 
        actor_count > 10
), 
AlternativeTitles AS (
    SELECT 
        a.name AS alternative_name, 
        t.title
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.person_id = t.id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    hc.title, 
    hc.production_year, 
    hc.actor_count, 
    hc.average_rating, 
    STRING_AGG(at.alternative_name, ', ') AS alternative_names
FROM 
    HighActorCount hc
LEFT JOIN 
    AlternativeTitles at ON hc.title = at.title
WHERE 
    hc.average_rating IS NOT NULL
GROUP BY 
    hc.title, hc.production_year, hc.actor_count, hc.average_rating
HAVING 
    COUNT(at.alternative_name) > 0
ORDER BY 
    hc.production_year DESC, 
    hc.actor_count DESC;
