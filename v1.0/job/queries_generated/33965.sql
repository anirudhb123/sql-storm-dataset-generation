WITH RecursiveCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
), 
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT cc.kind) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        comp_cast_type cc ON cc.id = (SELECT DISTINCT ci.person_role_id 
                                       FROM cast_info ci 
                                       WHERE ci.movie_id = t.id LIMIT 1)
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    rc.actor_name,
    rc.role_rank,
    md.keyword_count,
    md.company_count,
    NULLIF(md.keyword_count - md.company_count, 0) AS diff_count,
    COALESCE(NULLIF(md.keyword_count, 0), 'No Keywords') AS keyword_message
FROM 
    MovieDetails md
JOIN 
    RecursiveCast rc ON md.movie_id = rc.movie_id
WHERE 
    md.keyword_count > 3 OR 
    (md.company_count < 1 AND rc.role_rank = 1)
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;

This query does the following:

1. It uses a recursive CTE `RecursiveCast` to retrieve the hierarchy of cast members based on their role order (rank) in each movie.

2. It aggregates movie details in another CTE `MovieDetails`, grouping by movie title and production year while counting unique keywords and companies associated with each movie.

3. The main query selects relevant fields from `MovieDetails` and `RecursiveCast`, applying filtering criteria on keyword and company counts.

4. It uses `NULLIF` and `COALESCE` to demonstrate handling NULL values and provide custom messages.

5. The final output is ordered by `production_year` and `keyword_count` in descending order.
