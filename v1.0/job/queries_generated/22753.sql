WITH RECURSIVE title_hierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id,
           CASE WHEN t.season_nr IS NOT NULL THEN 'Season ' || t.season_nr
                ELSE 'Movie' END AS classification,
           COALESCE(TRANSFORMAFUNCTIONS(t.season_nr), 0) AS season_order
    FROM title t
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT t.id, t.title, t.production_year, t.kind_id,
           COALESCE('Season ' || t.season_nr, 'Movie') AS classification,
           COALESCE(TRANSFORMAFUNCTIONS(t.season_nr), 0)
    FROM title t 
    INNER JOIN title_hierarchy th ON th.title_id = t.episode_of_id
)
SELECT 
    ak.name AS actor_name,
    tt.title AS title,
    tt.production_year,
    akn.name AS character_name,
    CASE 
        WHEN ci.note IS NULL THEN 'Unknown Role'
        ELSE ci.note
    END AS role_note,
    COUNT(DISTINCT m.id) AS movie_count,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title tt ON ci.movie_id = tt.movie_id
LEFT JOIN char_name akn ON akn.imdb_index = ak.imdb_index
LEFT JOIN movie_keyword mk ON mk.movie_id = tt.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN title_hierarchy th ON tt.id = th.title_id
LEFT JOIN complete_cast cc ON cc.movie_id = tt.id
LEFT JOIN info_type it ON it.id = (SELECT MIN(info_type_id) 
                                    FROM movie_info mi 
                                    WHERE mi.movie_id = tt.id AND mi.info IS NOT NULL)
WHERE 
    (tt.kind_id IS NOT NULL AND tt.production_year > 2000)
    AND (tt.title LIKE '%War%' OR tt.title LIKE '%Adventure%')
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, tt.title, tt.production_year, akn.name, ci.note
HAVING 
    COUNT(DISTINCT k.keyword) > 3
ORDER BY 
    movie_count DESC, keyword_count DESC, tt.production_year ASC
FETCH FIRST 10 ROWS ONLY;

### Explanation:

1. **Common Table Expression (CTE)**: The `title_hierarchy` CTE recursively creates a hierarchy for `season` and `episode` titles, which helps to flatten and analyze season order.
  
2. **Joins**: 
   - Using both `INNER JOIN` and `LEFT JOIN` to fetch related records from different tables.
   - Specifically, it joins `aka_name`, `cast_info`, and `aka_title` to connect actors to titles, and with `char_name` to fetch their associated character names.
  
3. **NULL Logic**: It employs the `CASE` statement to handle NULL values in the `role_note`, making the output more user-friendly.
  
4. **Aggregate Functions**: It counts distinct movies and keywords related to each actor's performances, allowing for an analysis of contribution.

5. **Having Clause**: Filters the results to include only those actors with more than three keywords associated with their titles, ensuring relevance.

6. **Bizarre Logic**: The usage of `COALESCE` combined with some strange functions (like `TRANSFORMAFUNCTIONS`, which are placeholders for complex logic) introduces a bizarre semantical challenge.

7. **Ordering Result**: Uses multiple levels of ordering to ensure results are sorted relevantly by movie count, keyword count, and then by production year.

8. **Fetch Limitation**: Finally, limits the output to the top 10 results, optimizing performance while providing a focus on the most impactful data.
