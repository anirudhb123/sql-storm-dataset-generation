WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        rk.rnk AS rank,
        COUNT(DISTINCT mk.keyword) OVER (PARTITION BY mt.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, COUNT(DISTINCT mk.keyword) DESC) AS yearly_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT an.name, ',') AS actor_names,
        MIN(cmp.kind) AS company_kind,
        MAX(pinfo.info) AS additional_info
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cmp ON mc.company_type_id = cmp.id
    LEFT JOIN 
        person_info pinfo ON ci.person_id = pinfo.person_id
        AND pinfo.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio')
    GROUP BY 
        ci.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        cd.actor_names,
        cd.company_kind,
        rm.rank,
        cd.additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_names,
    COALESCE(fr.company_kind, 'Unknown') AS company_kind,
    fr.rank,
    CASE 
        WHEN fr.keyword_count > 5 THEN 'High'
        WHEN fr.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Moderate'
    END AS keyword_density,
    fr.additional_info
FROM 
    FinalResults fr
WHERE 
    fr.rank <= 10 
    AND (fr.production_year BETWEEN 2000 AND 2020 OR fr.production_year IS NULL)
ORDER BY 
    fr.production_year DESC, fr.rank;
