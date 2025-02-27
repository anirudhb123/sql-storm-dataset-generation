WITH RECURSIVE movie_paths AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS depth,
        ARRAY[m.id] AS path
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code IS NOT NULL
    UNION ALL
    SELECT 
        mp.movie_id,
        t.title,
        mp.depth + 1,
        mp.path || t.id
    FROM 
        movie_paths mp
    JOIN 
        movie_link ml ON ml.movie_id = mp.movie_id
    JOIN 
        title t ON t.id = ml.linked_movie_id
    WHERE 
        NOT t.id = ANY(mp.path)
),
member_info AS (
    SELECT 
        p.person_id,
        n.name,
        pi.info,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY pi.info) AS info_rank
    FROM 
        person_info pi
    JOIN 
        aka_name n ON n.person_id = pi.person_id
    JOIN 
        cast_info c ON c.person_id = p.person_id
    WHERE 
        pi.info IS NOT NULL
),
average_info AS (
    SELECT 
        person_id,
        AVG(LENGTH(info)) AS avg_length
    FROM 
        member_info
    GROUP BY 
        person_id
    HAVING 
        AVG(LENGTH(info)) > 10
),
final_info AS (
    SELECT 
        m.movie_id,
        m.title,
        a.avg_length,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY a.avg_length DESC) AS rn
    FROM 
        movie_paths m
    LEFT JOIN 
        average_info a ON a.person_id = (SELECT person_id FROM cast_info ci WHERE ci.movie_id = m.movie_id LIMIT 1)
)
SELECT 
    f.movie_id, 
    f.title, 
    f.avg_length
FROM 
    final_info f
WHERE 
    f.rn = 1 
    AND f.avg_length IS NOT NULL 
    AND f.title NOT LIKE '%unreleased%'
ORDER BY 
    f.avg_length DESC
LIMIT 10;

### Explanation:

1. **Recursive CTE `movie_paths`**: This part builds movie paths starting from entries in the `aka_title` table and including companies linked to these movies. It explores connections via the `movie_link` table to create paths through linked movies while avoiding cycles using an array.

2. **CTE `member_info`**: Here, data from `person_info` is combined with names from `aka_name` and `cast_info`, filtering non-null values and assigning a rank to each piece of information for every person.

3. **CTE `average_info`**: This computes the average length of non-null info strings per person, including only those with average lengths greater than 10 characters.

4. **CTE `final_info`**: In this part, the previously computed average lengths are joined back to `movie_paths` based on movies each person acted in, while also imposing a ranking.

5. **Final Selection**: The last SELECT statement retrieves movie details, excluding unreleased titles, and orders the output by average length in descending order, limited to the top 10 results.

This query tries to reflect complexity and interesting semantics through several layers of filtering, ranking, recursion, and string handling.
