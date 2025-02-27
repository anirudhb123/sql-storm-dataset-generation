WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        cast_info.movie_id,
        1 AS depth
    FROM 
        aka_name AS a
    JOIN 
        cast_info ON a.person_id = cast_info.person_id
    WHERE 
        a.name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        ah.depth + 1 AS depth
    FROM 
        ActorHierarchy AS ah
    JOIN 
        cast_info AS c ON ah.movie_id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        c.nr_order > 0 AND ah.actor_id <> c.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rank
    FROM 
        MovieDetails AS md
),
MoviesWithKeywords AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        movie_keyword AS mk ON rm.title = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        rm.title, rm.production_year, rm.actor_count
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.keywords,
    a.actor_name,
    a.depth
FROM 
    MoviesWithKeywords AS mw
LEFT JOIN 
    ActorHierarchy AS a ON mw.title = (
        SELECT title FROM title WHERE id = (
            SELECT movie_id FROM cast_info WHERE person_id = a.actor_id LIMIT 1)
    )
WHERE 
    mw.rank <= 5 
ORDER BY 
    mw.production_year DESC, mw.actor_count DESC; 
