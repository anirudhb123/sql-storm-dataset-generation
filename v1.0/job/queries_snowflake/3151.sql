
WITH MovieTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT pinfo.info, ', ') WITHIN GROUP (ORDER BY pinfo.info) AS actor_info
    FROM 
        cast_info c
    LEFT JOIN 
        person_info pinfo ON c.person_id = pinfo.person_id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        mt.keywords,
        ar.actor_count
    FROM 
        MovieTitles mt
    LEFT JOIN 
        ActorRoles ar ON mt.title_id = ar.movie_id
    WHERE 
        mt.production_year > 2000
)
SELECT 
    f.title,
    f.production_year,
    f.keywords,
    COALESCE(f.actor_count, 0) AS actor_count,
    ROW_NUMBER() OVER (PARTITION BY f.production_year ORDER BY f.actor_count DESC) AS rank_within_year
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC;
