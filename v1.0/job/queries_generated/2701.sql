WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(CASE WHEN k.keyword IS NOT NULL THEN k.keyword END) AS primary_keyword
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id
),
CompanyCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
RankedMovies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.actor_names,
        md.primary_keyword,
        COALESCE(cc.company_count, 0) AS company_count,
        RANK() OVER (ORDER BY md.total_cast DESC, md.production_year ASC) AS movie_rank
    FROM
        MovieDetails md
    LEFT JOIN
        CompanyCounts cc ON md.movie_id = cc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.actor_names,
    rm.primary_keyword,
    rm.company_count,
    CASE 
        WHEN rm.company_count = 0 THEN 'No Companies Involved'
        ELSE 'Companies Involved'
    END AS company_status
FROM 
    RankedMovies rm
WHERE 
    rm.total_cast > 5
    AND (rm.primary_keyword IS NOT NULL OR rm.company_count > 0)
ORDER BY 
    rm.movie_rank;
