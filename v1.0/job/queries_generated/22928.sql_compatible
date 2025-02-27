
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rank_by_id,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies_in_year
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
RoleStatistics AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(c.role_id) AS role_count
    FROM
        cast_info c
    LEFT JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
TitleKeyword AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
)
SELECT
    rm.movie_title,
    rm.production_year,
    rm.total_movies_in_year,
    COALESCE(rs.role, 'Unspecified') AS actor_role,
    COALESCE(rs.role_count, 0) AS number_of_roles,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.rank_by_id < 5 THEN 'Top 5'
        WHEN rm.rank_by_id BETWEEN 5 AND 10 THEN 'Middle'
        ELSE 'Lower Rank'
    END AS movie_ranking_category,
    CASE
        WHEN rs.role_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_presence
FROM
    RankedMovies rm
LEFT JOIN
    RoleStatistics rs ON rm.movie_id = rs.movie_id
LEFT JOIN
    TitleKeyword tk ON rm.movie_id = tk.movie_id
WHERE
    rm.production_year BETWEEN 1990 AND 2023
    AND (rm.total_movies_in_year > 1 OR (rs.role IS NOT NULL AND rs.role_count > 0))
ORDER BY 
    rm.production_year DESC, rm.rank_by_id;
