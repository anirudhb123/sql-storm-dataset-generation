
WITH RecursivePersonRoles AS (
    SELECT ci.person_id, ci.role_id, 
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    WHERE ci.note IS NOT NULL
),
MovieSummary AS (
    SELECT 
        mt.movie_id,
        t.title,
        COALESCE(MIN(ca.surname_pcode), 'unknown') AS surname_code,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS actor_note_presence,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT k.keyword) DESC) AS keyword_rank
    FROM aka_title mt
    JOIN title t ON mt.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN aka_name ca ON ci.person_id = ca.person_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.movie_id, t.title
),
TopRankedMovies AS (
    SELECT movie_id, title, surname_code, keyword_count
    FROM MovieSummary
    WHERE keyword_rank <= 10
),
MoviesWithRoles AS (
    SELECT 
        tr.title, 
        tr.surname_code, 
        COALESCE(rr.role_id, 0) AS role_id, 
        rr.role_order,
        tr.keyword_count
    FROM TopRankedMovies tr
    LEFT JOIN RecursivePersonRoles rr ON rr.person_id IN (
        SELECT ca.person_id
        FROM cast_info ca
        WHERE ca.movie_id = tr.movie_id
    )
    ORDER BY tr.keyword_count DESC, rr.role_order ASC
)
SELECT 
    mw.title,
    mw.surname_code,
    CASE 
        WHEN mw.role_order IS NULL THEN 'No Role' 
        WHEN mw.role_id = 0 THEN 'Unknown Role' 
        ELSE rt.role 
    END AS role_description,
    mw.keyword_count
FROM MoviesWithRoles mw
LEFT JOIN role_type rt ON mw.role_id = rt.id
WHERE mw.keyword_count > 5
ORDER BY mw.keyword_count DESC, mw.title ASC;
