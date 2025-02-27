WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
ActorData AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cp.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cp ON mc.company_id = cp.id
    WHERE 
        cp.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    ad.name AS actor_name,
    COUNT(DISTINCT ad.movie_id) AS total_movies,
    c.movie_count AS total_companies,
    tk.keywords
FROM 
    RankedTitles t
LEFT JOIN 
    ActorData ad ON t.title_id = ad.movie_id
LEFT JOIN 
    CompanyMovieCount c ON t.title_id = c.movie_id
LEFT JOIN 
    TitleKeywords tk ON t.title_id = tk.movie_id
WHERE 
    t.rn = 1
    AND (ad.role_rank IS NULL OR ad.role_rank <= 3)
GROUP BY 
    t.title, t.production_year, ad.name, c.movie_count, tk.keywords
HAVING 
    COUNT(DISTINCT ad.movie_id) > 2
ORDER BY 
    t.production_year DESC, total_movies DESC
LIMIT 10;
