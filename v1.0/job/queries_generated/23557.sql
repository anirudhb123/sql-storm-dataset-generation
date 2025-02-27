WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id, 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.person_id, a.name
    HAVING COUNT(DISTINCT c.movie_id) >= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(r.production_year, 'No Year') AS production_year,
        COALESCE(kw.keywords, 'No Keywords') AS keywords,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM aka_title m
    LEFT JOIN RankedTitles r ON m.id = r.title_id AND r.rn = 1
    LEFT JOIN MovieKeywords kw ON m.id = kw.movie_id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year > 2000
    GROUP BY m.id, m.title, r.production_year, kw.keywords
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keywords,
    COALESCE(a.movie_count, 0) AS actor_movie_count,
    CASE 
        WHEN f.total_roles > 15 THEN 'Jam-Packed'
        WHEN f.total_roles BETWEEN 5 AND 15 THEN 'Moderate'
        ELSE 'Sparse'
    END AS role_density
FROM FilteredMovies f
LEFT JOIN ActorMovies a ON f.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
ORDER BY f.production_year DESC, f.title;

This query breaks down as follows:

1. **RankedTitles CTE**: It ranks titles by production year and title name, filtering for non-null production years.
2. **ActorMovies CTE**: This CTE counts all movies per actor, filtering to include only those actors with 5 or more movie appearances.
3. **MovieKeywords CTE**: It aggregates keywords for each movie into a single string.
4. **FilteredMovies CTE**: This CTE gathers relevant movie info, including handling NULL production years and roles, and summarizes data.
5. **Final Selection**: The main query pulls from `FilteredMovies`, joining on `ActorMovies` and classifying the density of roles in each movie, providing an insightful view of movie and actor relationships. 

The query specifically uses constructs like `WITH`, `ROW_NUMBER()`, `COALESCE`, `HAVING`, and `GROUP BY`, while also implementing complex conditional logic with `CASE`, illustrating various SQL capabilities.
