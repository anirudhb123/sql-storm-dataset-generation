WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM
        aka_title t
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN c.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%') THEN 1 ELSE 0 END) AS has_lead
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
CompanyMovieCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.actor_count, 0) AS actor_count,
    CASE WHEN cd.has_lead = 1 THEN 'Yes' ELSE 'No' END AS has_lead,
    COALESCE(cmc.company_count, 0) AS company_count,
    COUNT(DISTINCT km.keyword) AS keyword_count,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
FROM
    RankedMovies rm
LEFT JOIN
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    CompanyMovieCounts cmc ON rm.movie_id = cmc.movie_id
LEFT JOIN
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    keyword km ON mk.keyword_id = km.id
WHERE 
    rm.year_rank <= 5 AND
    (cd.actor_count IS NULL OR cd.actor_count > 5)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.actor_count, cd.has_lead, cmc.company_count
ORDER BY 
    rm.production_year DESC, actor_count DESC NULLS LAST;
