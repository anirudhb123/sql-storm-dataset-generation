WITH RecursiveMovieDates AS (
    SELECT
        m.id AS movie_id,
        m.production_year,
        m.title,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year, m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name AS actor_name,
        rmd.movie_id,
        rmd.title AS movie_title,
        rmd.production_year
    FROM 
        aka_name a
    INNER JOIN
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN
        RecursiveMovieDates rmd ON ci.movie_id = rmd.movie_id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role IN ('Actor', 'Actress'))
    AND 
        rmd.rn <= 5  -- Limit to top 5 movies per year
),
MovieKeywordCounts AS (
    SELECT
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY
        m.id
),
MoviesWithKeywordFilter AS (
    SELECT 
        tm.*,
        mkc.keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN
        MovieKeywordCounts mkc ON tm.movie_id = mkc.movie_id
    WHERE 
        mkc.keyword_count > 2 -- Movies with more than 2 keywords
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS num_actors_or_actresses
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.role_id IN (SELECT id FROM role_type WHERE role IN ('Actor', 'Actress'))
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MoviesFinal AS (
    SELECT 
        mwkf.*,
        cr.company_name,
        cr.company_type,
        cr.num_actors_or_actresses,
        RANK() OVER (PARTITION BY mwkf.movie_title ORDER BY mwkf.production_year, mwkf.keyword_count DESC) AS rank
    FROM 
        MoviesWithKeywordFilter mwkf
    LEFT JOIN 
        CompanyRoles cr ON mwkf.movie_id = cr.movie_id
)
SELECT 
    DISTINCT mf.movie_title,
    mf.production_year,
    mf.actor_name,
    mf.keyword_count,
    mf.company_name,
    mf.company_type,
    mf.num_actors_or_actresses
FROM 
    MoviesFinal mf
WHERE 
    mf.rank = 1 -- Select the top ranked movie for each title
AND 
    mf.production_year BETWEEN 2000 AND 2023 -- Specify the range of production years
ORDER BY 
    mf.production_year, mf.keyword_count DESC, mf.actor_name;
