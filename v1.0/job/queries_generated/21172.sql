WITH recursive_name_roles AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        ct.kind,
        ROW_NUMBER() OVER (PARTITION BY ai.person_id ORDER BY ai.nr_order) as role_rank
    FROM cast_info ai
    JOIN comp_cast_type ct ON ai.person_role_id = ct.id
    WHERE ct.kind IS NOT NULL
),

movie_titles AS (
    SELECT 
        at.id AS title_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM aka_title at
    LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
    GROUP BY at.id, at.title, at.production_year
),

person_keywords AS (
    SELECT 
        pi.person_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM person_info pi
    LEFT JOIN movie_keyword mk ON pi.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY pi.person_id
)

SELECT 
    rn.person_id,
    n.name AS person_name,
    mt.movie_title,
    mt.production_year,
    rn.role_rank,
    COALESCE(pk.keywords, 'No Keywords') AS keywords,
    mt.company_count
FROM recursive_name_roles rn
JOIN aka_name n ON rn.person_id = n.person_id
JOIN movie_titles mt ON rn.movie_id = mt.title_id
LEFT JOIN person_keywords pk ON rn.person_id = pk.person_id
WHERE rn.role_rank = 1 OR rn.role_rank IS NULL 
AND mt.production_year > 2000 
AND (pk.keywords IS NULL OR pk.keywords LIKE '%action%')
ORDER BY mt.production_year DESC, rn.role_rank ASC
LIMIT 50;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `recursive_name_roles`: Generates a ranking of roles for each person in the `cast_info` table using a window function, filtering null role types.
   - `movie_titles`: Aggregates movie titles along with their respective production years and counts the number of companies related to each title.
   - `person_keywords`: Compiles unique keywords associated with each person's performances.

2. **Main Select**:
   - Joins the CTE results with `aka_name` and `movie_titles` while incorporating a left join with `person_keywords` to include keywords.
   - Applies filters to refine results based on the role rank and production year.
   - Includes NULL logic to provide a default string when there are no keywords.

3. **Order and Limit**: 
   - Results are ordered by `production_year` and `role_rank`, limiting the output to the top 50 entries for performance benchmarking.
