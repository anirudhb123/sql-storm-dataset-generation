
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
),

FilteredMovies AS (
    SELECT 
        rt.aka_id,
        rt.aka_name,
        rt.title_id,
        rt.movie_title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
),

AggregatedInfo AS (
    SELECT 
        fm.aka_id,
        fm.aka_name,
        COUNT(DISTINCT fm.title_id) AS movie_count,
        LISTAGG(DISTINCT fm.movie_title, ', ') WITHIN GROUP (ORDER BY fm.movie_title) AS movies_list,
        LISTAGG(DISTINCT CONCAT(fm.movie_title, ' (', fm.production_year, ')'), ', ') WITHIN GROUP (ORDER BY fm.movie_title) AS detailed_movies_list
    FROM 
        FilteredMovies fm
    GROUP BY 
        fm.aka_id, fm.aka_name
)

SELECT 
    ai.id AS actor_id,
    ai.name AS actor_name,
    ag.movie_count,
    ag.movies_list,
    ag.detailed_movies_list
FROM 
    aka_name ai
JOIN 
    AggregatedInfo ag ON ai.id = ag.aka_id
WHERE 
    ag.movie_count > 3
ORDER BY 
    ag.movie_count DESC;
