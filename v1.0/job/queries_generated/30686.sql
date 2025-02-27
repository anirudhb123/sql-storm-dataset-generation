WITH RECURSIVE actor_movies AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year >= 2000
),
movie_keywords AS (
    SELECT
        m.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
),
company_details AS (
    SELECT
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies m
    JOIN
        company_name co ON m.company_id = co.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
)
SELECT
    am.actor_name,
    STRING_AGG(DISTINCT am.movie_title || ' (' || am.production_year || ')', '; ') AS movies,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cd.company_name || ' (' || cd.company_type || ')', '; ') AS companies
FROM
    actor_movies am
LEFT JOIN
    movie_keywords mk ON am.movie_title = mk.movie_id
LEFT JOIN
    company_details cd ON am.movie_title = cd.movie_id
WHERE
    am.movie_rank <= 3  -- Get only top 3 movies for each actor
GROUP BY
    am.actor_name
HAVING
    COUNT(DISTINCT am.movie_title) > 1  -- Actors who've worked in multiple movies
ORDER BY
    am.actor_name;

### Explanation:
1. **Recursive CTE**: `actor_movies` generates a list of actors along with their movies produced after 2000. It also ranks movies for each actor based on the production year.
2. **CTE for Keywords**: `movie_keywords` retrieves keywords associated with each movie, ranking them for display purposes.
3. **CTE for Companies**: `company_details` provides company name and type associated with each movie.
4. **Main Query**: Combines results using LEFT JOINs and collects data:
   - Aggregates movie titles, keywords, and company details.
   - Filters results to include only actors with more than one movie.
   - Orders results alphabetically by actor name. 

This complex setup showcases a variety of SQL functionalities such as CTEs, window functions, string aggregation, filtering, and complex joins, making it suitable for performance benchmarking.
