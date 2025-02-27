WITH RankedMovies AS (
    SELECT
        a.id AS aka_id,
        a.person_id,
        a.name AS actor_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS actor_rank,
        COALESCE(SUM(mk.keyword_id) FILTER (WHERE k.keyword LIKE '%Drama%'), 0) AS drama_keywords
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        a.id, a.person_id, a.name, t.id, t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT t.production_year) AS total_movies,
        AVG(t.production_year) AS avg_release_year,
        SUM(CASE WHEN t.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_since_2000
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        a.person_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
),
FinalResults AS (
    SELECT
        rm.actor_name,
        rm.title,
        rm.production_year,
        ai.total_movies,
        ai.avg_release_year,
        ai.movies_since_2000,
        cd.company_count,
        cd.companies,
        LAG(rm.title, 1, 'N/A') OVER (PARTITION BY rm.person_id ORDER BY rm.production_year) AS previous_title,
        CASE 
            WHEN rm.drama_keywords > 0 THEN 'Drama Enthusiast'
            ELSE 'Diverse Actor'
        END AS actor_type
    FROM
        RankedMovies rm
    JOIN
        ActorInfo ai ON rm.person_id = ai.person_id
    LEFT JOIN
        CompanyDetails cd ON rm.title_id = cd.movie_id
    WHERE
        rm.actor_rank = 1
        AND (ai.total_movies > 10 OR cd.company_count > 3)
        AND rm.production_year IS NOT NULL
    ORDER BY 
        rm.production_year DESC
)
SELECT 
    *,
    CASE 
        WHEN actor_type = 'Drama Enthusiast' AND company_count > 5 
        THEN 'Award Potential'
        ELSE 'Standard'
    END AS potential_award
FROM 
    FinalResults
WHERE 
    previous_title IS NOT NULL
    AND actor_name IS NOT NULL
    AND title IS NOT NULL;
