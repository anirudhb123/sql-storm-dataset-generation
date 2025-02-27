WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    GROUP BY 
        m.title, m.production_year
),
ActorsWithSpecialRoles AS (
    SELECT 
        ak.name,
        ci.note AS role_note
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE 'Lead%')
),
MoviesWithActorNotes AS (
    SELECT 
        DISTINCT m.title,
        ak.name AS actor_name,
        mi.keywords,
        COALESCE(ak.md5sum, 'Unknown') AS actor_md5sum
    FROM 
        MovieInfo mi
    LEFT JOIN 
        ActorsWithSpecialRoles ak ON mi.title IN (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM cast_info WHERE person_id = ak.person_id))
)
SELECT 
    ma.actor_name,
    ma.title,
    ma.production_year,
    ma.keywords,
    CASE 
        WHEN ma.actor_md5sum IS NULL THEN 'No MD5 available'
        ELSE ma.actor_md5sum
    END AS actor_md5sum,
    COUNT(mu.linked_movie_id) AS related_movies
FROM 
    MoviesWithActorNotes ma
LEFT JOIN 
    movie_link mu ON ma.title = (SELECT title FROM aka_title WHERE id = mu.movie_id)
GROUP BY 
    ma.actor_name, ma.title, ma.keywords, ma.actor_md5sum
HAVING 
    COUNT(mu.linked_movie_id) > 1 OR (COUNT(mu.linked_movie_id) = 1 AND ma.keywords IS NOT NULL)
ORDER BY 
    ma.actor_name, ma.title;
