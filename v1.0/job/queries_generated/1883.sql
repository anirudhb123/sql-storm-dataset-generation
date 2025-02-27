WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year
), movie_info_filter AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM
        movie_info mi
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    GROUP BY
        mi.movie_id
), movie_stats AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mif.info_details, 'No Awards') AS awards_info
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_info_filter mif ON rm.movie_id = mif.movie_id
    WHERE
        rm.rank <= 5
), final_output AS (
    SELECT
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.awards_info,
        CASE
            WHEN ms.cast_count > 10 THEN 'High Cast'
            WHEN ms.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
            ELSE 'Low Cast'
        END AS cast_density,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = ms.movie_id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE 'Distributor%')) AS distributor_count
    FROM
        movie_stats ms
)
SELECT
    f.title,
    f.production_year,
    f.cast_count,
    f.awards_info,
    f.cast_density,
    COALESCE(f.distributor_count, 0) AS distributor_total
FROM
    final_output f
ORDER BY
    f.production_year DESC, f.cast_count DESC;
