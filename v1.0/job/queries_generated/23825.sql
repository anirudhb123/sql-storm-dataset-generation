WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM title m
    WHERE m.production_year IS NOT NULL
),

actor_role_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles_played
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.person_id
),

movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title m ON mk.movie_id = m.id
    GROUP BY m.id
),

company_distribution AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)

SELECT 
    rm.year_rank,
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ac.person_id, 0) AS actor_id,
    ac.movie_count AS films_with_actor,
    ac.roles_played,
    COALESCE(mk.keywords, 'None') AS movie_keywords,
    COALESCE(cd.companies, 'No companies') AS production_companies,
    cd.company_count
FROM ranked_movies rm
LEFT JOIN actor_role_counts ac ON ac.movie_count > 1 AND ac.person_id IN (
    SELECT DISTINCT c.person_id
    FROM cast_info c
    WHERE c.movie_id = rm.movie_id
)
LEFT JOIN movies_with_keywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN company_distribution cd ON cd.movie_id = rm.movie_id
WHERE rm.year_rank <= 5
ORDER BY rm.production_year DESC, rm.year_rank
FETCH FIRST 10 ROWS ONLY;

This query performs multiple complex tasks:
1. **CTEs** are used to create several temporary result sets.
2. It uses **window functions** `ROW_NUMBER()` to rank movies by production year.
3. **String aggregation** (`STRING_AGG`) is used to unify multiple entries into a single field.
4. It also applies conditionals and **NULL logic** using `COALESCE` to provide default values.
5. **Subqueries** within the join conditions and the outer query implement filtering for actors with more than one film.
6. The final result is sorted and limited, showcasing various production details and roles for a handful of movies as a benchmarking feature.

