
WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        CASE 
            WHEN t.production_year IS NULL THEN 'Unknown Year'
            WHEN t.production_year < 2000 THEN 'Before 2000'
            ELSE '2000 and After' 
        END AS production_period
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) AS mk ON mk.movie_id = t.id
), MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
), CompData AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') WITHIN GROUP (ORDER BY cn.name, ct.kind) AS companies_info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(mc.num_actors, 0) AS number_of_actors,
    r.keywords,
    r.production_period,
    CASE 
        WHEN cd.companies_info IS NULL THEN 'Independent'
        ELSE cd.companies_info 
    END AS production_companies,
    ROW_NUMBER() OVER (PARTITION BY r.production_period ORDER BY r.production_year DESC) AS title_rank
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    MovieCast mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    CompData cd ON r.movie_id = cd.movie_id
WHERE 
    (r.production_year IS NOT NULL OR r.production_year IS NULL) 
    AND (r.production_year > 1980 OR r.keywords ILIKE '%action%')
    AND NOT EXISTS (
        SELECT 1 FROM movie_info mi 
        WHERE mi.movie_id = r.movie_id AND mi.info_type_id = 1 AND mi.info LIKE '%blockbuster%'
    )
ORDER BY 
    r.production_period, 
    r.title;
