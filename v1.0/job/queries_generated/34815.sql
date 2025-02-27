WITH RECURSIVE actor_movies AS (
    SELECT 
        ca.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name kn ON ca.person_id = kn.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    WHERE 
        kn.name LIKE 'Johnny%' -- Focus on actors with names starting with 'Johnny'
),
company_statistics AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(mc.id) AS contribution_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
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
    am.person_id,
    k.keywords,
    am.title,
    am.production_year,
    cs.company_name,
    cs.contribution_count,
    COALESCE(cs.contribution_count, 0) AS total_contributions
FROM 
    actor_movies am
LEFT JOIN 
    company_statistics cs ON am.movie_rank <= 5 AND am.movie_rank IS NOT NULL
LEFT JOIN 
    keyword_summary k ON am.movie_rank <= (SELECT COUNT(*) FROM actor_movies) AND am.movie_id = k.movie_id
WHERE 
    am.movie_year >= 2000 -- Focus on movies released since 2000
ORDER BY 
    am.person_id, am.production_year DESC
LIMIT 100;

### Explanation:
1. **CTE `actor_movies`**: This recursive CTE retrieves movies that actors with names starting with "Johnny" have participated in, ranking them by production year.
2. **CTE `company_statistics`**: This summarizes companies that contributed to movies by counting their appearances.
3. **CTE `keyword_summary`**: This aggregates keywords associated with each movie using `STRING_AGG` to combine them into a comma-separated string.
4. **Main Query**:
   - Selects data from the `actor_movies` CTE and joins it with `company_statistics` and `keyword_summary`. 
   - The joins are made based on the condition that focuses on the top 5 movies per actor or the movie ID.
   - The logic also includes `COALESCE` to handle possible NULL values in company contributions.
   - Results are limited to movies released since 2000 and ordered for better readability with a limit set for performance benchmarking.
