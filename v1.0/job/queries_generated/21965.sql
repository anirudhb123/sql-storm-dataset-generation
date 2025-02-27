WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),

MovieWithKeywords AS (
    SELECT 
        tt.id AS title_id,
        tt.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM (SELECT DISTINCT id, title FROM aka_title) tt
    LEFT JOIN movie_keyword mk ON tt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY tt.id, tt.title
),

PersonDetails AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        a.imdb_index AS actor_index,
        c.note AS character_note,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY c.nr_order) AS character_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN name p ON a.person_id = p.imdb_id
    WHERE a.name IS NOT NULL
),

MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),

FinalMovies AS (
    SELECT 
        m.title,
        m.production_year,
        m.keywords,
        pc.actor_name,
        mcd.company_names,
        mcd.company_types
    FROM MovieWithKeywords m
    LEFT JOIN PersonDetails pc ON pc.character_rank = 1
    LEFT JOIN MovieCompanyDetails mcd ON m.id = mcd.movie_id
    WHERE m.title IS NOT NULL
)

SELECT 
    title,
    production_year,
    COALESCE(keywords, 'No keywords') AS keywords,
    COALESCE(actor_name, 'Unknown') AS lead_actor,
    COALESCE(company_names, 'No companies') AS production_companies,
    COALESCE(company_types, 'N/A') AS company_types
FROM FinalMovies
WHERE production_year > 2000
ORDER BY production_year DESC, title ASC;

-- Special case handling for titles that may include the word "Untitled" and have no keywords
UNION ALL 
SELECT 
    m.title,
    m.production_year,
    'Untitled project' AS keywords,
    'N/A' AS lead_actor,
    'N/A' AS production_companies,
    'N/A' AS company_types
FROM aka_title m
WHERE m.title ILIKE '%untitled%'
AND NOT EXISTS (SELECT 1 FROM MovieWithKeywords mk WHERE mk.title_id = m.id)
ORDER BY production_year DESC, title ASC
LIMIT 50;
