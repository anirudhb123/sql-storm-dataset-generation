WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
), 
PersonInfo AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        a.imdb_index AS actor_index,
        a.md5sum,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.id
),
CompleteMovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        m.keywords,
        p.actor_name,
        p.actor_index,
        p.roles
    FROM 
        MovieInfo m
    LEFT JOIN 
        PersonInfo p ON m.movie_id = p.person_id
)
SELECT 
    cm.movie_id,
    cm.title,
    cm.production_year,
    cm.kind_id,
    cm.keywords,
    STRING_AGG(DISTINCT cm.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT cm.roles, ', ') AS roles
FROM 
    CompleteMovieInfo cm
GROUP BY 
    cm.movie_id, cm.title, cm.production_year, cm.kind_id, cm.keywords
ORDER BY 
    cm.production_year DESC, cm.title;

