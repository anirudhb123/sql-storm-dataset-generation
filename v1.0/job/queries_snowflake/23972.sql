WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        CAST(t.kind_id AS varchar) AS kind,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL AND
        t.production_year > 2000
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COALESCE(MAX(pi.info), 'No Info') AS personal_info,
        COUNT(distinct c.movie_id) AS total_movies,
        SUM(CASE WHEN t.production_year < 2020 THEN 1 ELSE 0 END) AS pre_2020_movies
    FROM 
        aka_name a
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.person_id, a.name
),
FilteredActors AS (
    SELECT 
        r.actor_name,
        r.movie_title,
        r.production_year,
        ad.personal_info,
        ad.total_movies,
        ad.pre_2020_movies
    FROM 
        RankedMovies r
    JOIN 
        ActorDetails ad ON r.aka_id = ad.person_id
    WHERE 
        r.rank <= 5
)
SELECT 
    f.actor_name,
    f.movie_title,
    f.production_year,
    f.personal_info,
    f.total_movies,
    f.pre_2020_movies
FROM 
    FilteredActors f
WHERE 
    (f.personal_info IS NOT NULL OR f.total_movies >= 3)
ORDER BY 
    f.production_year DESC,
    f.actor_name;
