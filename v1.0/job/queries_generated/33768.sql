WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id,
        ct.kind AS role,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name an ON c.person_id = an.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    JOIN 
        kind_type kt ON at.kind_id = kt.id
    JOIN 
        comp_cast_type cct ON c.role_id = cct.id
    JOIN 
        title t ON at.id = t.id
    LEFT JOIN 
        movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.person_id, ct.kind
),
RankedActors AS (
    SELECT 
        am.person_id,
        am.role,
        am.movie_count,
        RANK() OVER (PARTITION BY am.role ORDER BY am.movie_count DESC) AS rank
    FROM 
        ActorMovies am
),
TopActors AS (
    SELECT 
        ra.person_id,
        ra.role,
        ra.movie_count
    FROM 
        RankedActors ra
    WHERE 
        ra.rank <= 5
)
SELECT 
    an.name AS actor_name,
    ta.role AS actor_role,
    ta.movie_count AS total_movies,
    COALESCE(k.keyword, 'No Keywords') AS keywords,
    t.production_year,
    t.title,
    CASE 
        WHEN t.production_year IS NULL THEN 'Unknown Year'
        ELSE t.production_year::text
    END AS production_year_display
FROM 
    TopActors ta
JOIN 
    aka_name an ON ta.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT m.id FROM aka_title m WHERE m.episode_of_id IS NULL AND m.production_year = (SELECT MAX(production_year) FROM aka_title WHERE season_nr IS NOT NULL))
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    cast_info ci ON ci.person_id = an.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    title t ON at.id = t.id
WHERE 
    an.name IS NOT NULL
ORDER BY 
    ta.role, total_movies DESC;
