WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(NULLIF(m.production_year,0), NULL) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        NULL, -- Placeholder for recursive structure
        'Parent of ' || mh.title,
        mh.production_year,
        rank
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.rank = 1  -- Only grab the top-ranked movie in each kind
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NOT NULL AND ci.note != '' THEN LENGTH(ci.note) ELSE NULL END) AS avg_role_note_length
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        a.person_id
),
MoviesWithKeyWords AS (
    SELECT 
        mt.movie_id, 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        aka_title m ON mt.movie_id = m.id
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id, m.title
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        cnt.name AS company_name,
        m.title,
        m.production_year
    FROM 
        movie_companies mc
    JOIN 
        company_name cnt ON mc.company_id = cnt.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        cnt.country_code IS NOT NULL
),
FinalMetrics AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year, 
        COALESCE(as.movie_count, 0) AS actor_movie_count,
        COALESCE(keywords, 'No Keywords') AS keywords,
        COALESCE(company_info.company_name, 'Independent') AS company_name
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorStats as ON mh.movie_id = as.person_id
    LEFT JOIN 
        MoviesWithKeyWords mwk ON mh.movie_id = mwk.movie_id
    LEFT JOIN 
        CompanyMovieInfo company_info ON mh.movie_id = company_info.movie_id
)
SELECT 
    *,
    CASE 
        WHEN production_year IS NULL THEN 'Unknown Year'
        WHEN production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    RANK() OVER (ORDER BY production_year DESC) AS ranking
FROM 
    FinalMetrics
WHERE 
    (company_name IS NOT NULL OR actor_movie_count > 0)
    AND (keywords IS NOT NULL OR production_year < 2010)
ORDER BY 
    era DESC, ranking ASC;
