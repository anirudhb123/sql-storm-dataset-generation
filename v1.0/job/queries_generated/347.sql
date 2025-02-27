WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS has_awards,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) as rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    LEFT JOIN
        movie_info mi ON a.id = mi.movie_id
    LEFT JOIN
        person_info pi ON c.person_id = pi.person_id
    GROUP BY
        a.id
), FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.actor_count,
        rm.has_awards
    FROM
        RankedMovies rm
    WHERE
        rm.actor_count > 5 AND rm.rank <= 10
)
SELECT
    fm.title,
    fm.production_year,
    kt.kind AS kind_description,
    COALESCE(fm.has_awards, 'No') AS awards_status,
    ROW_NUMBER() OVER (ORDER BY fm.production_year DESC, fm.actor_count DESC) AS overall_rank
FROM
    FilteredMovies fm
JOIN
    kind_type kt ON fm.kind_id = kt.id
ORDER BY
    fm.production_year DESC, fm.actor_count DESC;
