WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT
        c.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT p.id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info c
    JOIN
        aka_name ak ON ak.person_id = c.person_id
    JOIN
        person_info p ON p.person_id = c.person_id
    WHERE
        ak.name IS NOT NULL
    GROUP BY
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name c ON c.id = mc.company_id
    GROUP BY
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ami.actor_count, 0) AS actor_count,
    COALESCE(ami.actor_names, 'None') AS actor_names,
    COALESCE(mci.company_count, 0) AS company_count,
    COALESCE(mci.company_names, 'None') AS company_names
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovieInfo ami ON rt.title_id = ami.movie_id
LEFT JOIN 
    MovieCompanies mci ON rt.title_id = mci.movie_id
WHERE 
    rt.rn <= 5
ORDER BY 
    rt.production_year DESC, rt.title ASC;
