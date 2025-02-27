WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
MovieInfoWithKeywords AS (
    SELECT 
        m.movie_id,
        m.info,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_info m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.info
),
CastAndCompany AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        cast_info ci
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    GROUP BY 
        ci.movie_id
),
SelectedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(ki.total_cast, 0) AS total_cast,
        COALESCE(ki.total_companies, 0) AS total_companies,
        ARRAY_AGG(DISTINCT mk.keywords) AS all_keywords
    FROM 
        title t
    LEFT JOIN 
        CastAndCompany ki ON t.id = ki.movie_id
    LEFT JOIN 
        MovieInfoWithKeywords mk ON t.id = mk.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE 'feature%')
    GROUP BY 
        t.id, t.title, t.production_year, ki.total_cast, ki.total_companies
)
SELECT 
    sm.title_id,
    sm.title,
    sm.production_year,
    sm.total_cast,
    sm.total_companies,
    CASE 
        WHEN sm.total_cast = 0 THEN 'No cast available'
        WHEN sm.total_companies > 5 THEN 'Produced by multiple companies'
        ELSE 'Standard film'
    END AS film_category,
    STRING_AGG(DISTINCT unnest(sm.all_keywords), ', ') AS keywords_list
FROM 
    SelectedMovies sm
LEFT JOIN 
    RankedTitles rt ON sm.title_id = rt.title_id AND rt.rank <= 3
WHERE 
    rt.aka_id IS NOT NULL
GROUP BY 
    sm.title_id, sm.title, sm.production_year, sm.total_cast, sm.total_companies
ORDER BY 
    sm.production_year DESC, sm.total_cast DESC, sm.total_companies ASC
LIMIT 100;
