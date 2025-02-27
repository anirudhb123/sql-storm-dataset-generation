WITH RECURSIVE top_companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

actor_rankings AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY COUNT(c.person_id) DESC) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id, ak.name
),

production_years AS (
    SELECT 
        mt.id AS movie_id,
        mt.production_year,
        COUNT(DISTINCT a.actor_name) FILTER (WHERE r.actor_rank <= 3) AS top_actors_count 
    FROM 
        aka_title mt
    LEFT JOIN 
        actor_rankings r ON mt.id = r.movie_id
    GROUP BY 
        mt.id, mt.production_year
)

SELECT 
    p.movie_id,
    p.production_year,
    COALESCE(tc.total_companies, 0) AS companies_count,
    COALESCE(p.top_actors_count, 0) AS top_actors_count,
    CASE 
        WHEN COALESCE(tc.total_companies, 0) = 0 THEN 'No Companies' 
        ELSE 'Companies Exist' 
    END AS company_status,
    STRING_AGG(r.actor_name, ', ' ORDER BY r.actor_rank) AS top_actors
FROM 
    production_years p
LEFT JOIN 
    top_companies tc ON p.movie_id = tc.movie_id
LEFT JOIN 
    actor_rankings r ON p.movie_id = r.movie_id AND r.actor_rank <= 3
GROUP BY 
    p.movie_id, p.production_year, tc.total_companies, p.top_actors_count
ORDER BY 
    p.production_year DESC, companies_count DESC;

### Explanation:
- The query uses Common Table Expressions (CTEs) to first calculate the top companies associated with each movie, followed by ranking actors by their appearance in movies.
- `top_companies` is built to summarize how many companies are tied to each movie.
- `actor_rankings` ranks the actors based on their appearances in each film.
- `production_years` captures the count of top actors, specifically those with a rank of 3 or less.
- The main SELECT combines information from `production_years`, `top_companies`, and `actor_rankings`.
- A `CASE` statement is included to determine if any companies exist for each movie.
- Finally, it aggregates the names of the top actors for each movie, allowing double counting to be avoided through filtering on rank.
- The output is ordered by production year and the count of companies in descending order.
