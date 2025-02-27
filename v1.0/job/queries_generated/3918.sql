WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
),
ActorStats AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT cd.movie_id) AS total_movies,
        AVG(cd.production_year) AS avg_production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info cd ON ak.person_id = cd.person_id
    GROUP BY 
        ak.person_id, ak.name
),
TopActors AS (
    SELECT 
        person_id,
        name,
        total_movies,
        avg_production_year,
        ROW_NUMBER() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorStats
    WHERE 
        total_movies > 5
)
SELECT 
    ma.title,
    ma.production_year,
    t.name AS actor_name,
    t.total_movies,
    t.avg_production_year,
    string_agg(DISTINCT md.keyword, ', ') AS keywords
FROM 
    MovieDetails ma
LEFT JOIN 
    TopActors t ON ma.movie_id = (
        SELECT 
            c.movie_id
        FROM 
            cast_info c
        WHERE 
            c.person_id = t.person_id
        ORDER BY 
            c.nr_order
        LIMIT 1
    )
LEFT JOIN 
    (SELECT DISTINCT movie_id, keyword FROM movie_keyword) md ON ma.movie_id = md.movie_id
WHERE 
    t.rank IS NOT NULL
GROUP BY 
    ma.title, ma.production_year, t.name, t.total_movies, t.avg_production_year
ORDER BY 
    t.total_movies DESC, ma.production_year DESC
LIMIT 10;
