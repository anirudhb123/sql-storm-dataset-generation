WITH RECURSIVE actor_movies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.note IS NULL -- Only consider roles with no special notes
),
company_activity AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    a.person_id,
    a.title AS most_recent_movie,
    a.production_year,
    COALESCE(ca.company_name, 'Independent') AS production_company,
    ca.movie_count AS movies_by_company,
    ks.keywords AS movie_keywords
FROM 
    actor_movies a
LEFT JOIN 
    company_activity ca ON a.movie_id = ca.movie_id
LEFT JOIN 
    keyword_summary ks ON a.movie_id = ks.movie_id
WHERE 
    a.movie_rank = 1 -- Only consider the most recent movie per actor
ORDER BY 
    a.production_year DESC, a.person_id;

### Explanation:
- The query uses recursive Common Table Expressions (CTEs) to create a list of actors and the most recent movies they have worked on (`actor_movies`).
- A second CTE, `company_activity`, aggregates movie production companies per movie and counts the number of movies each company has produced.
- The third CTE `keyword_summary` gathers the keywords associated with each movie into a concatenated string.
- In the final selection, we join these CTEs to show each actor, their most recent movie, the production company for that movie, the count of movies produced by the company, and any keywords associated with the movie.
- The use of `COALESCE` is to manage NULL values, providing 'Independent' as a default when no company is associated.
- The results are ordered by the production year and actor ID.
