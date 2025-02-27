WITH RecursiveActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        mk.keywords,
        ROW_NUMBER() OVER (ORDER BY md.actor_count DESC, md.production_year ASC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        MovieKeywords mk ON md.movie_id = mk.movie_id
    WHERE 
        md.actor_count > 0
)
SELECT 
    t.title,
    t.production_year,
    t.actor_count,
    t.keywords,
    ARRAY_AGG(DISTINCT r.actor_name) FILTER (WHERE r.role_rank <= 3) AS relevant_roles,
    CASE WHEN rank < 6 THEN 'Top 5'
         WHEN rank < 11 THEN 'Top 10'
         ELSE 'Outside Top 10' END AS ranking_category
FROM 
    TopMovies t
LEFT JOIN 
    RecursiveActorRoles r ON t.movie_id = r.movie_id
GROUP BY 
    t.movie_id, t.title, t.production_year, t.actor_count, t.keywords, rank 
ORDER BY 
    t.actor_count DESC, t.production_year;
