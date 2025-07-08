
WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank,
        a.person_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND t.title IS NOT NULL
),
GenreTitles AS (
    SELECT DISTINCT
        k.keyword AS genre_keyword,
        t.title AS title,
        t.production_year
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title t ON mk.movie_id = t.movie_id
    WHERE 
        k.keyword LIKE '%Drama%' AND t.production_year IS NOT NULL
),
TopActorGenres AS (
    SELECT 
        rt.actor_name,
        LISTAGG(DISTINCT gt.genre_keyword, ', ') WITHIN GROUP (ORDER BY gt.genre_keyword) AS genres,
        COUNT(DISTINCT rt.movie_title) AS movie_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        GenreTitles gt ON rt.movie_title = gt.title AND rt.production_year = gt.production_year
    WHERE 
        rt.title_rank = 1
    GROUP BY 
        rt.actor_name
    HAVING 
        COUNT(DISTINCT rt.movie_title) > 1
)
SELECT 
    ta.actor_name,
    COALESCE(ta.genres, 'No Genres Available') AS genres,
    ta.movie_count,
    CASE 
        WHEN ta.movie_count > 5 THEN 'Prolific Actor'
        WHEN ta.movie_count BETWEEN 3 AND 5 THEN 'Moderate Actor'
        ELSE 'Newcomer'
    END AS actor_classification
FROM 
    TopActorGenres ta
ORDER BY 
    ta.movie_count DESC;
