WITH RECURSIVE company_hierarchy AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        cn.country_code,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
  
    UNION ALL

    SELECT 
        mc.movie_id,
        cn.name,
        cn.country_code,
        ch.level + 1
    FROM 
        company_hierarchy ch
    JOIN 
        movie_companies mc ON ch.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        ch.level < 5  -- limiting the depth of recursion
)

SELECT 
    a.title,
    a.production_year,
    a.kind_id,
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    ch.company_name,
    ch.country_code,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CASE 
        WHEN p.gender IS NULL THEN 0 
        ELSE 1 
    END) AS gender_unknown_ratio,
    RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
FROM 
    aka_title a
LEFT JOIN 
    cast_info c ON a.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON a.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    company_hierarchy ch ON a.movie_id = ch.movie_id
LEFT JOIN 
    name p ON ak.id = p.id
WHERE 
    a.production_year IS NOT NULL 
    AND a.production_year BETWEEN 2000 AND 2023
    AND c.nr_order = 1  -- leading actor/actress
GROUP BY 
    a.id, a.title, a.production_year, a.kind_id, ak.name, ch.company_name, ch.country_code
ORDER BY 
    a.production_year DESC, actor_count DESC;

### Explanation:
- **CTE (Common Table Expression)**: A recursive CTE named `company_hierarchy` is used to explore the hierarchy of companies connected to movies, limiting the recursion depth to 5 levels.
- **LEFT JOINs**: Several LEFT JOINs are employed to combine information across various tables (like `aka_title`, `cast_info`, `aka_name`, etc.).
- **Aggregation**: The `ARRAY_AGG` function collects distinct keywords associated with each title, and `COUNT(DISTINCT c.person_id)` calculates the number of unique actors.
- **NULL Logic**: The `CASE` statement computes a ratio of actors with unknown gender.
- **Window Function**: `RANK()` provides a ranking of movies by production year.
- **Complex Predicates**: Filters on production year and the primary cast role, as well as checks for non-nullity of production years.
