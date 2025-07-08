
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_actors <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    CASE
        WHEN mc.company_rank IS NULL THEN 'N/A'
        WHEN mc.company_rank = 1 THEN 'Top Company'
        ELSE 'Other Companies'
    END AS company_category,
    RANK() OVER (ORDER BY tm.production_year DESC) AS year_rank
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id AND mc.company_rank = 1 
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.production_year > 2000 
    AND EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = tm.movie_id 
        AND ci.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
    )
ORDER BY 
    tm.production_year DESC;
