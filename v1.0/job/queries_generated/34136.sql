WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(c.person_id, -1) AS person_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        t.kind_id
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mc.person_id, -1) AS person_id,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        m.kind_id
    FROM 
        MovieCTE m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info mc ON cc.subject_id = mc.person_id 
    LEFT JOIN 
        aka_name ak ON mc.person_id = ak.person_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    STRING_AGG(DISTINCT m.actor_name, ', ') AS all_actors,
    COUNT(DISTINCT m.person_id) AS actor_count,
    MAX(m.production_year) OVER (PARTITION BY m.kind_id) AS max_year_in_kind,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieCTE m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%')
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT m.person_id) > 1
ORDER BY 
    m.production_year DESC;

### Explanation:
1. **Recursive CTE (MovieCTE)**: This CTE recursively gathers movie details along with associated actor names.
2. **LEFT JOINs**: Used to connect `aka_title` with `cast_info` and `aka_name`, fetching potentially missing actor data.
3. **Aggregation and String Functions**: The query aggregates actor names into a concatenated string and counts distinct actors per movie.
4. **Window Functions**: It computes the maximum production year for each movie kind.
5. **Complicated Predicates**: Filters results for movies that match specific criteria (Drams) using a subquery on `kind_type`.
6. **HAVING clause**: Ensures each movie listed has more than one actor, which reflects some movie richness.
7. **Ordering**: Results are sorted by production year in descending order for the latest movies first.
