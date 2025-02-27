WITH RankedTitles AS (
    SELECT
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.id) AS title_rank,
        COUNT(b.id) AS keyword_count
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword b ON mk.keyword_id = b.id
    GROUP BY
        a.id, a.title, a.production_year
),
PersonRoles AS (
    SELECT
        c.person_id,
        c.role_id,
        pt.role AS person_role,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info c
    JOIN
        role_type pt ON c.role_id = pt.id
    GROUP BY
        c.person_id, c.role_id
),
CompCast AS (
    SELECT
        cc.movie_id,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
        SUM(CASE WHEN cnt.movie_count > 1 THEN 1 ELSE 0 END) AS multi_movie_actors
    FROM
        complete_cast cc
    JOIN
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN
        PersonRoles cnt ON ci.person_id = cnt.person_id
    GROUP BY
        cc.movie_id
),
FinalResults AS (
    SELECT
        t.title,
        t.production_year,
        r.title_rank,
        c.cast_names,
        COALESCE(c.multi_movie_actors, 0) AS multi_movie_actors
    FROM
        RankedTitles r
    LEFT JOIN
        CompCast c ON r.title_rank = 1 AND r.title IS NOT NULL
    LEFT JOIN
        title t ON r.title = t.title AND r.production_year = t.production_year
    WHERE
        r.keyword_count > 5
)
SELECT
    fr.title,
    fr.production_year,
    fr.cast_names,
    fr.multi_movie_actors,
    CASE 
        WHEN fr.multi_movie_actors IS NULL THEN 'No Multi-Movie Actors'
        WHEN fr.multi_movie_actors > 5 THEN 'Star-Studded'
        ELSE 'Regular Cast'
    END AS cast_quality
FROM
    FinalResults fr
ORDER BY
    fr.production_year DESC,
    fr.title;
