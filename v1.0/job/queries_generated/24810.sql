WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
),
PersonDetails AS (
    SELECT
        ak.person_id,
        ak.name,
        pi.info AS birth_date
    FROM
        aka_name ak
    LEFT JOIN person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
),
MovieRoles AS (
    SELECT
        c.movie_id,
        rt.role,
        COUNT(c.id) AS role_count
    FROM
        cast_info c
    INNER JOIN role_type rt ON c.role_id = rt.id
    GROUP BY
        c.movie_id, rt.role
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT
    fm.title,
    fm.production_year,
    gm.name AS starring_actor,
    mr.role,
    cm.company_name,
    cm.company_type,
    COALESCE(pd.birth_date, 'Unknown') AS actor_birth_date
FROM
    FilteredMovies fm
LEFT JOIN cast_info ci ON fm.title_id = ci.movie_id
LEFT JOIN PersonDetails pd ON ci.person_id = pd.person_id
LEFT JOIN MovieRoles mr ON fm.title_id = mr.movie_id
LEFT JOIN CompanyDetails cm ON fm.title_id = cm.movie_id
WHERE
    (cm.company_type IS NULL OR cm.company_type NOT LIKE '%Distributor%')
    AND fm.production_year IS NOT NULL
    AND fm.cast_count > 0
ORDER BY 
    fm.production_year DESC, fm.title;
