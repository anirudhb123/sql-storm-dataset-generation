WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS num_actors,
        COUNT(DISTINCT m.company_id) AS num_companies,
        AVG(mp.info) AS avg_runtime
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        movie_info mp ON t.id = mp.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'runtime')
    GROUP BY 
        t.title
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        ak.name AS aka_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        name a ON a.id = ak.person_id
),
FilteredMovies AS (
    SELECT 
        ms.movie_title, 
        ms.num_actors,
        ms.num_companies,
        ms.avg_runtime
    FROM 
        MovieStats ms
    WHERE 
        ms.num_actors > 5 AND 
        ms.avg_runtime IS NOT NULL
)
SELECT 
    DISTINCT fm.movie_title,
    fm.num_actors,
    fm.num_companies,
    COALESCE(ROUND(fm.avg_runtime::numeric, 2), 'N/A') AS avg_runtime_formatted,
    STRING_AGG(ad.actor_name || ' (aka: ' || COALESCE(ad.aka_name, 'N/A') || ')', ', ') AS actors
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorDetails ad ON ad.movie_id IN (SELECT id FROM aka_title WHERE title = fm.movie_title)
GROUP BY 
    fm.movie_title, fm.num_actors, fm.num_companies, fm.avg_runtime
ORDER BY 
    fm.num_actors DESC, fm.movie_title ASC
LIMIT 20;
### Query Breakdown:
1. **CTE - MovieStats**: Collects aggregate movie statistics including the number of actors and companies associated with each movie, while also calculating the average runtime (assuming 'runtime' is the relevant info type).

2. **CTE - ActorDetails**: Joins `aka_name`, `cast_info`, and `name` to get actor names and their aliases, along with a rank for each actor based on their name.

3. **CTE - FilteredMovies**: Filters movies from `MovieStats` that have more than 5 actors and a known average runtime.

4. **Final Select**: Pulls movie details from `FilteredMovies`, left joining with the `ActorDetails` to concatenate actor information into a single string. It applies a `COALESCE` for formatting the average runtime to handle potential NULLs.

5. **Distinct and Aggregation**: The `STRING_AGG` function introduced to compile actor names together, ensuring to handle different alias cases.

6. **Ordering and Limit**: Orders results by the number of actors and then by movie title, limiting the output to the top 20 movies meeting the criteria.
