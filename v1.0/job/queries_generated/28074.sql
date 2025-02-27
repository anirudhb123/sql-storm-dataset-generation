WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year > 2000
),

ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles_played
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        p.id, p.name
),

MovieActors AS (
    SELECT 
        m.title,
        m.production_year,
        a.actor_name,
        a.roles_played
    FROM 
        RankedMovies m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        ActorDetails a ON cc.subject_id = a.person_id
    WHERE 
        m.rn = 1
)

SELECT 
    ma.title,
    ma.production_year,
    ma.actor_name,
    ma.roles_played,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    MovieActors ma
JOIN 
    movie_keyword mk ON ma.movie_id = mk.movie_id
GROUP BY 
    ma.title, ma.production_year, ma.actor_name, ma.roles_played
ORDER BY 
    ma.production_year DESC, keyword_count DESC;
