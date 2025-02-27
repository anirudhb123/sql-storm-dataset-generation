WITH RankedMovies AS (
    SELECT 
        a.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(m.production_year) AS avg_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mi ON a.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND c.nr_order IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopRankedMovies AS (
    SELECT 
        title,
        actor_count,
        avg_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
ActorDetails AS (
    SELECT 
        n.name AS actor_name,
        a.title AS movie_title,
        CAST(SUBSTRING(m.info FROM 'Year:(\d{4})') AS INTEGER) AS film_year,
        COALESCE(m.note, 'N/A') AS note
    FROM 
        TopRankedMovies a
    JOIN 
        cast_info c ON a.title = a.title
    JOIN 
        aka_name n ON c.person_id = n.person_id
    LEFT JOIN 
        movie_info m ON a.title = m.info
)

SELECT 
    ad.actor_name, 
    ad.movie_title, 
    ad.film_year, 
    ad.note
FROM 
    ActorDetails ad
WHERE 
    ad.film_year IS NOT NULL 
ORDER BY 
    ad.film_year DESC, 
    ad.actor_name;
