WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.person_id,
        p.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_title AS a
    JOIN 
        cast_info AS c ON a.id = c.movie_id
    JOIN 
        aka_name AS p ON c.person_id = p.person_id
    WHERE 
        a.production_year >= 2000
        AND a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieKeywords AS (
    SELECT 
        DISTINCT m.movie_id,
        k.keyword
    FROM 
        movie_keyword AS m
    JOIN 
        keyword AS k ON m.keyword_id = k.id
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        RankedMovies AS rm
    JOIN 
        MovieKeywords AS mk ON rm.movie_title = mk.movie_id
    GROUP BY 
        actor_name
)
SELECT 
    rs.actor_name,
    rs.total_movies,
    rs.keywords,
    (SELECT COUNT(*) FROM movie_companies WHERE movie_id IN (SELECT DISTINCT movie_id FROM RankedMovies)) AS total_movies_with_company,
    (SELECT COUNT(*) FROM complete_cast WHERE subject_id IN (SELECT DISTINCT person_id FROM RankedMovies)) AS total_unique_actors
FROM 
    ActorStats AS rs
ORDER BY 
    rs.total_movies DESC;
