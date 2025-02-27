WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS total_cast
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(c.person_id) > 5
), MovieInfoCTE AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT concat(mi.info_type_id, ': ', mi.info), '; ') AS movie_infos
    FROM 
        RecursiveMovieCTE m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
), PersonCTE AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movies_featured
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 3
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.total_cast,
    m.movie_infos,
    p.name AS actor_name,
    p.movies_featured
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    MovieInfoCTE m ON r.movie_id = m.movie_id
JOIN 
    PersonCTE p ON p.movies_featured > 3
ORDER BY 
    r.production_year DESC, 
    r.total_cast DESC;
