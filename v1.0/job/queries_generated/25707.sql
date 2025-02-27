SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    r.role AS actor_role,
    COALESCE(cn.name, 'N/A') AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.person_id, t.id, r.role, cn.name
ORDER BY 
    t.production_year DESC, a.name;

### Explanation:
- **Selected Columns**: The query retrieves the actor's name, movie title, year of production, associated keywords, actor's role, and the name of the production company.
- **Joins**:
  - `aka_name` is joined with `cast_info` to connect actors to their roles.
  - `cast_info` is joined with `title` to get the movie details.
  - `movie_keyword` and `keyword` are joined to aggregate movie keywords.
  - `movie_companies` and `company_name` are left joined to obtain the company name associated with the movie, if any.
  - `role_type` is left joined to include the role of the actor.
- **Filters**: It includes only movies released between 2000 and 2023 and ensures that the actor’s name is present.
- **Grouping**: The query groups results by actor and movie to allow the aggregation of keywords.
- **Ordering**: Results are ordered by production year in descending order and then by actor's name.
