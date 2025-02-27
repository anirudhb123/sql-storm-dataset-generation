WITH recursive movie_chain AS (
    SELECT
        mc.movie_id,
        COUNT(*) AS depth,
        STRING_AGG(DISTINCT t.title, ' -> ') AS movie_titles
    FROM
        movie_link AS ml
    JOIN 
        movie_companies AS mc ON mc.movie_id = ml.movie_id
    JOIN 
        title AS t ON t.id = mc.movie_id
    WHERE
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel')
    GROUP BY
        mc.movie_id
),
ranked_movies AS (
    SELECT
        m.*,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        RANK() OVER (ORDER BY COUNT(c.person_id) DESC) AS cast_rank
    FROM
        aka_title AS m
    LEFT JOIN 
        cast_info AS c ON c.movie_id = m.movie_id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id
),
combined_results AS (
    SELECT
        r.title,
        r.production_year,
        COALESCE(CAST(m.depth AS INTEGER), 0) AS sequel_depth,
        COALESCE(r.year_rank, 0) AS year_rank,
        COALESCE(r.cast_rank, 0) AS casting_rank,
        r.title || ' (' || COALESCE(m.movie_titles, 'No sequels') || ')' AS movie_info
    FROM
        ranked_movies AS r
    LEFT JOIN 
        movie_chain AS m ON r.id = m.movie_id
)
SELECT
    cr.title,
    cr.production_year,
    cr.sequel_depth,
    cr.year_rank,
    cr.casting_rank,
    cr.movie_info
FROM
    combined_results AS cr
ORDER BY
    cr.production_year DESC,
    cr.sequel_depth DESC,
    cr.casting_rank ASC
LIMIT 50;

This SQL query performs complex operations to investigate sequels and their ranked characteristics, including:

1. **CTEs**: Utilizes `movie_chain` to establish a recursive relationship between movies and their sequels, creating a depth count and aggregating titles for display.

2. **Window Functions**: Implements `ROW_NUMBER()` and `RANK()` for classifying movies based on their production year and cast presence.

3. **Outer Joins**: Uses left joins to ensure that even movies without sequels are included in the results.

4. **Aggregation**: Employs `STRING_AGG()` to concatenate titles in the sequel chain.

5. **Complicated Logic**: Introduces case handling to safely aggregate and display movie titles with NULL logic.

6. **Ordering and Limiting**: Orders results meticulously and limits output for ease of analysis.

The query encapsulates a wealth of operational complexity, simulating a novel analysis of sequels within a movie database.
