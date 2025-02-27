WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        episode_of_id,
        1 AS level
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL

    UNION ALL

    SELECT 
        a.id,
        a.title,
        a.episode_of_id,
        mh.level + 1
    FROM 
        aka_title a
    INNER JOIN 
        movie_hierarchy mh ON a.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(mh.level, 0) AS hierarchy_level,
        COUNT(ci.person_role_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        movie_hierarchy mh ON m.id = mh.movie_id
    GROUP BY 
        m.movie_id, m.title, mh.level
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        hierarchy_level,
        cast_count,
        null_notes_count,
        average_order,
        RANK() OVER (ORDER BY cast_count DESC, hierarchy_level ASC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.hierarchy_level,
    tm.cast_count,
    tm.null_notes_count,
    tm.average_order,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    GROUP_CONCAT(DISTINCT cn.name) AS companies_involved
FROM 
    top_movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.hierarchy_level, tm.cast_count, tm.null_notes_count, tm.average_order, ct.kind
ORDER BY 
    tm.cast_count DESC, tm.hierarchy_level ASC;

This SQL query creates a recursive Common Table Expression (CTE) to build a hierarchy of movies based on episodes and their parent titles. It then aggregates data about the cast and provides a ranking based on the number of cast members, while calculating the average order of roles and counting NULL notes in the cast information. Finally, it retrieves the top 10 movies along with their associated company types and a list of companies involved. The final result is ordered by the number of cast members and the hierarchy level.
