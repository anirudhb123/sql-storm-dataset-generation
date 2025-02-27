WITH MovieSummary AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.id) AS role_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
    GROUP BY
        a.id, a.name, t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT
        actor_id,
        actor_name,
        movie_title,
        production_year,
        keywords,
        role_count,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY production_year DESC) AS rank
    FROM
        MovieSummary
)
SELECT 
    r.actor_id,
    r.actor_name,
    r.movie_title,
    r.production_year,
    COALESCE(r.keywords, 'No keywords') AS keywords,
    r.role_count,
    (SELECT AVG(roles) FROM (SELECT COUNT(*) AS roles FROM cast_info WHERE person_id = r.actor_id GROUP BY movie_id) AS actor_roles) AS avg_roles_per_movie
FROM 
    RankedMovies r
WHERE 
    r.rank <= 5
ORDER BY 
    r.actor_name, r.production_year DESC;
