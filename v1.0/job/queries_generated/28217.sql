WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        m.name AS company_name,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, m.name
),
top_titles AS (
    SELECT 
        title_id, 
        title_name, 
        production_year, 
        company_name 
    FROM 
        ranked_titles 
    WHERE 
        rank <= 5
)
SELECT 
    tt.title_name, 
    tt.production_year, 
    tt.company_name, 
    COUNT(pi.id) AS info_count,
    ARRAY_AGG(DISTINCT pi.info) AS infos
FROM 
    top_titles tt
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = tt.title_id)
GROUP BY 
    tt.title_name, tt.production_year, tt.company_name
ORDER BY 
    tt.production_year DESC, info_count DESC;

This SQL query performs the following actions:

1. **Common Table Expression (CTE) `ranked_titles`:** Calculates the number of cast members for each title and ranks the titles within each production year based on the cast count.

2. **CTE `top_titles`:** Selects the top 5 titles per production year based on the number of cast members.

3. **Final Selection:** For the top titles, it retrieves the title name, production year, and associated company names. It also counts the number of related info entries and aggregates the distinct info into an array.

4. **Ordering:** The results are ordered by production year and number of info entries. 

This query benchmarks various string processing capabilities, including aggregation and array functions, by dealing with multiple table joins and complex ordering.
