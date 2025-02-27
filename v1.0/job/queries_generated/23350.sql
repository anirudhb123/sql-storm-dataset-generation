WITH RecursiveFilmData AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank,
        c.note AS cast_note,
        CASE 
            WHEN c.nr_order IS NULL THEN 'Unrated'
            ELSE 'Rated ' || c.nr_order::text
        END AS order_status,
        COALESCE(c.note, 'No note available') AS detailed_note
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
MovieStats AS (
    SELECT 
        title_id,
        COUNT(DISTINCT person_id) AS total_actors,
        AVG(nr_order) AS average_order,
        SUM(CASE WHEN order_status = 'Unrated' THEN 1 ELSE 0 END) AS unrated_count
    FROM 
        RecursiveFilmData
    GROUP BY 
        title_id
),
FilmSummary AS (
    SELECT 
        md.title,
        md.production_year,
        COALESCE(ms.total_actors, 0) AS total_actors,
        COALESCE(ms.average_order, 0) AS average_order,
        ms.unrated_count
    FROM 
        aka_title md
    LEFT JOIN 
        MovieStats ms ON md.id = ms.title_id
    WHERE 
        md.production_year BETWEEN 2000 AND 2020
)
SELECT 
    fs.title,
    fs.production_year,
    fs.total_actors,
    fs.average_order,
    CASE 
        WHEN fs.unrated_count > 0 THEN CONCAT('This movie has ', fs.unrated_count::text, ' unrated actors.')
        ELSE 'All actors rated.'
    END AS rating_summary
FROM 
    FilmSummary fs
WHERE 
    fs.total_actors > 5
ORDER BY 
    fs.production_year DESC,
    fs.total_actors DESC
LIMIT 10;

### Explanation:
- **CTE (`WITH` clauses)**:
  - `RecursiveFilmData` computes data on each actor's contribution to movies while providing a rank based on production years, handling NULLs with conditional expressions.
  - `MovieStats` aggregates the data on titles, counting unique actors and calculating average order ratings.
  - `FilmSummary` gathers the title and actors' data but only for movies produced between 2000 and 2020, using `LEFT JOIN` to include those without appearances.

- **Complexity**: 
  - The query uses window functions, COALESCE for NULL handling, and a `CASE` statement to categorize order ratings.
  - It incorporates filtering and ordering to ensure meaningful returns based on dynamically calculated conditions.

- **Final Selection**:
  - The result set returns details only for movies with notable cast sizes and a summary of unrated actors.
