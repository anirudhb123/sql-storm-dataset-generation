WITH Recursive_CTE AS (
    SELECT 
        ca.person_id, 
        COUNT(*) AS title_count
    FROM 
        cast_info ca
    INNER JOIN 
        title t ON ca.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(*) > 2
), 
Top_Persons AS (
    SELECT 
        rn.person_id,
        ak.name,
        rn.title_count,
        COALESCE(CAST(p.info AS TEXT), 'No Info') AS person_info
    FROM 
        Recursive_CTE rn
    INNER JOIN 
        aka_name ak ON rn.person_id = ak.person_id
    LEFT JOIN 
        person_info p ON rn.person_id = p.person_id AND p.info_type_id = 1
    WHERE 
        ak.name IS NOT NULL
), 
Title_With_Keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
Final_Output AS (
    SELECT 
        tp.person_id,
        tp.name,
        tp.title_count,
        twk.title,
        twk.keywords,
        CASE 
            WHEN tp.title_count IS NULL THEN 'N/A'
            ELSE ROUND(tp.title_count::NUMERIC / NULLIF(rn.title_count, 0), 2)
        END AS ratio
    FROM 
        Top_Persons tp
    LEFT JOIN 
        Title_With_Keywords twk ON tp.title_count < 5
    ORDER BY 
        tp.title_count DESC, twk.title
)

SELECT 
    person_id,
    name,
    title_count,
    title,
    keywords,
    ratio
FROM 
    Final_Output
WHERE 
    title IS NOT NULL
UNION ALL
SELECT 
    NULL AS person_id,
    'Summary' AS name,
    COUNT(*) AS title_count,
    NULL AS title,
    NULL AS keywords,
    NULL AS ratio
FROM 
    Final_Output
WHERE 
    title_count IS NOT NULL
HAVING 
    COUNT(*) > 0;

### Explanation:
1. **Recursive_CTE**: Counts the titles linked to each person, filtering for only those who have worked on more than 2 titles since the year 2000.
  
2. **Top_Persons**: Combines the result of the first CTE with the `aka_name` table and a left join on `person_info` to fetch additional information about the person while handling NULL cases with `COALESCE`.

3. **Title_With_Keywords**: Gathers all titles and their associated keywords. Uses `STRING_AGG` to concatenate keywords into a single string.

4. **Final_Output**: Joins the results from `Top_Persons` with `Title_With_Keywords` where the person's title count is less than 5. Also features a ratio calculation to show the person's title count against the overall count.

5. **Final SELECT**: Teams the data from `Final_Output`, removing null titles and adding a UNION ALL for summary information.

This SQL query utilizes multiple advanced constructs and logical corner cases such as handling NULL values and calculating metrics based on conditional logic, providing a comprehensive output useful for performance benchmarking.
