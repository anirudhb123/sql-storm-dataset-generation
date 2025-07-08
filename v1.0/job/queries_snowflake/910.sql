
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    GROUP BY 
        m.movie_id
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        ac.actor_count,
        ci.companies,
        COALESCE(mii.info, 'No Info') AS additional_info
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorCount ac ON r.movie_id = ac.movie_id
    LEFT JOIN 
        CompanyInfo ci ON r.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mii ON r.movie_id = mii.movie_id AND mii.info_type_id = 1
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS actor_count,
    md.companies,
    md.additional_info,
    (SELECT 
        COUNT(DISTINCT k.keyword) 
     FROM 
        movie_keyword mk 
     JOIN 
        keyword k ON mk.keyword_id = k.id 
     WHERE 
        mk.movie_id = md.movie_id) AS keyword_count
FROM 
    MovieDetails md
WHERE 
    (md.production_year >= 2000 AND md.actor_count > 5) 
    OR (md.companies IS NOT NULL AND md.additional_info LIKE '%Award%')
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
