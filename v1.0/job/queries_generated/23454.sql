WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
GenreCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT kt.keyword) AS genre_count
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id
),
ActorRoleCounts AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.person_role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        at.title,
        at.production_year,
        gc.genre_count,
        arc.actor_count,
        arc.role_count
    FROM 
        aka_title at
    LEFT JOIN 
        GenreCounts gc ON at.movie_id = gc.movie_id
    LEFT JOIN 
        ActorRoleCounts arc ON at.movie_id = arc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.genre_count,
    COALESCE(md.actor_count, 0) AS actor_count,
    COALESCE(md.role_count, 0) AS role_count,
    CASE 
        WHEN md.genre_count > 3 THEN 'Diverse Genre'
        WHEN md.genre_count IS NULL THEN 'Unknown Genre'
        ELSE 'Limited Genre'
    END AS genre_diversity,
    CASE 
        WHEN md.actor_count > 10 THEN 'Star-studded'
        ELSE 'Regular Cast'
    END AS cast_type,
    nt.name AS notable_actor,
    t.title AS notable_movie
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id LIMIT 1)
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    name nt ON an.id = nt.id AND nt.gender IS NOT NULL
LEFT JOIN 
    title t ON t.id = (SELECT linked_movie_id FROM movie_link WHERE movie_id = md.title LIMIT 1)
ORDER BY 
    md.production_year DESC, 
    md.genre_count DESC,
    md.title;
