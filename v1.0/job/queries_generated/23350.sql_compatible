
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
            ELSE CONCAT('Rated ', CAST(c.nr_order AS text))
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
        COALESCE(ms.unrated_count, 0) AS unrated_count
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
        WHEN fs.unrated_count > 0 THEN CONCAT('This movie has ', CAST(fs.unrated_count AS text), ' unrated actors.')
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
